import Foundation
import CryptoKit

/// 安全相关错误类型
enum SecurityError: Error {
    case invalidKey           // 无效的密钥
    case encryptionFailed     // 加密失败
    case decryptionFailed     // 解密失败
    case invalidData          // 无效的数据
}

/// 安全服务类
/// 提供加密、解密和密钥派生功能
/// 使用 AES-256-GCM 加密算法和 HKDF 密钥派生
class SecurityService {
    
    /// 生成随机盐值
    /// - Returns: 32 字节的随机数据，用于密钥派生
    /// - Note: 使用系统安全随机数生成器
    static func generateSalt() throws -> Data {
        var salt = Data(count: 32)
        let result = salt.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        guard result == errSecSuccess else {
            throw SecurityError.encryptionFailed
        }
        return salt
    }

    /// 从密码和盐值派生加密密钥
    /// - Parameters:
    ///   - password: 用户输入的主密码
    ///   - salt: 随机盐值
    /// - Returns: 256 位对称密钥
    /// - Note: 使用 HKDF-SHA256 算法，增强密码强度，防止暴力破解
    static func deriveKey(password: String, salt: Data) -> SymmetricKey {
        let inputKey = SymmetricKey(data: password.data(using: .utf8)!)
        // 使用 HKDF 和 SHA256 派生密钥
        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKey,
            salt: salt,
            info: Data(),
            outputByteCount: 32  // 256 位密钥
        )
        return derivedKey
    }

    /// 加密数据
    /// - Parameters:
    ///   - data: 需要加密的原始数据
    ///   - key: 对称加密密钥
    /// - Returns: 加密后的数据（包含 nonce 和 tag）
    /// - Throws: SecurityError.encryptionFailed 如果加密失败
    /// - Note: 使用 AES-256-GCM 模式，提供认证加密
    static func encrypt(data: Data, key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else {
                throw SecurityError.encryptionFailed
            }
            return combined
        } catch {
            throw SecurityError.encryptionFailed
        }
    }

    /// 解密数据
    /// - Parameters:
    ///   - combinedData: 加密后的数据（包含 nonce 和 tag）
    ///   - key: 对称解密密钥
    /// - Returns: 解密后的原始数据
    /// - Throws: SecurityError.decryptionFailed 如果解密失败或数据被篡改
    /// - Note: AES-GCM 会自动验证数据完整性
    static func decrypt(combinedData: Data, key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            throw SecurityError.decryptionFailed
        }
    }
}
