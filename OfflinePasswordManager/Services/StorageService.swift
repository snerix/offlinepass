import Foundation
import CryptoKit

/// 加密容器数据结构
/// 存储盐值和加密后的数据
struct EncryptedContainer: Codable {
    let salt: Data            // 密钥派生用的盐值
    let encryptedData: Data   // 加密后的密码数据
}

/// 存储服务类
/// 负责将加密后的密码数据保存到本地文件系统
class StorageService {
    /// 加密文件名
    private let fileName = "secrets.enc"
    
    /// 存储目录 URL
    private let directoryURL: URL

    /// 初始化存储服务
    /// - Parameter directoryURL: 可选的自定义存储目录，默认使用 Documents 目录
    init(directoryURL: URL? = nil) {
        if let url = directoryURL {
            self.directoryURL = url
        } else {
            self.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        }
    }
    
    /// 加密文件的完整路径
    private var fileURL: URL {
        directoryURL.appendingPathComponent(fileName)
    }

    /// 保存密码数据
    /// - Parameters:
    ///   - items: 密码条目数组
    ///   - key: 加密密钥
    ///   - salt: 盐值，用于下次登录时派生密钥
    /// - Throws: 加密或写入文件失败
    func save(items: [PasswordItem], key: SymmetricKey, salt: Data) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(items)
        
        let encryptedData = try SecurityService.encrypt(data: data, key: key)
        let container = EncryptedContainer(salt: salt, encryptedData: encryptedData)
        
        let containerData = try encoder.encode(container)
        // 使用原子写入，防止文件损坏
        try containerData.write(to: fileURL, options: .atomic)
    }

    /// 加载密码数据
    /// - Parameter key: 解密密钥（必须使用文件中的盐值派生）
    /// - Returns: 密码条目数组，如果文件不存在则返回空数组
    /// - Throws: 解密或解析失败（密码错误或数据损坏）
    func load(key: SymmetricKey) throws -> [PasswordItem] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let container = try decoder.decode(EncryptedContainer.self, from: data)
        
        let decryptedData = try SecurityService.decrypt(combinedData: container.encryptedData, key: key)
        return try decoder.decode([PasswordItem].self, from: decryptedData)
    }
    
    /// 获取存储的盐值（无需解密）
    /// - Returns: 盐值，如果文件不存在或读取失败则返回 nil
    /// - Note: 用于登录时派生正确的解密密钥
    func getSalt() -> Data? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let container = try JSONDecoder().decode(EncryptedContainer.self, from: data)
            return container.salt
        } catch {
            return nil
        }
    }
    
    /// 检查是否存在密码数据文件
    /// - Returns: true 表示已设置过主密码，false 表示首次使用
    func hasExistingStore() -> Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }
}
