import Foundation
import CryptoKit
import UniformTypeIdentifiers

struct ExportData: Codable {
    let version: String
    let salt: Data
    let encryptedData: Data
    let exportDate: Date
}

class ExportService {
    static let fileExtension = "pwmbackup"
    static let currentVersion = "1.0"
    
    static func exportData(items: [PasswordItem], password: String) throws -> Data {
        let salt = try SecurityService.generateSalt()
        let key = SecurityService.deriveKey(password: password, salt: salt)
        
        let encoder = JSONEncoder()
        let itemsData = try encoder.encode(items)
        
        let sealedBox = try AES.GCM.seal(itemsData, using: key)
        
        guard let combinedData = sealedBox.combined else {
            throw ExportError.fileCorrupted
        }
        
        let exportData = ExportData(
            version: currentVersion,
            salt: salt,
            encryptedData: combinedData,
            exportDate: Date()
        )
        
        return try encoder.encode(exportData)
    }
    
    static func importData(from fileData: Data, password: String) throws -> [PasswordItem] {
        let decoder = JSONDecoder()
        let exportData = try decoder.decode(ExportData.self, from: fileData)
        
        guard exportData.version == currentVersion else {
            throw ExportError.unsupportedVersion
        }
        
        let key = SecurityService.deriveKey(password: password, salt: exportData.salt)
        
        let sealedBox = try AES.GCM.SealedBox(combined: exportData.encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        return try decoder.decode([PasswordItem].self, from: decryptedData)
    }
    
    static func createExportURL(data: Data) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "passwords_\(Date().timeIntervalSince1970).\(fileExtension)"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try data.write(to: fileURL)
        return fileURL
    }
}

enum ExportError: Error, LocalizedError {
    case unsupportedVersion
    case invalidPassword
    case fileCorrupted
    
    var errorDescription: String? {
        switch self {
        case .unsupportedVersion:
            return "备份文件版本不兼容"
        case .invalidPassword:
            return "密码错误"
        case .fileCorrupted:
            return "备份文件已损坏"
        }
    }
}
