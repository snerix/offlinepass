import Foundation
import LocalAuthentication
import Security

enum BiometricError: Error {
    case notAvailable
    case authenticationFailed
    case keychainError
    case passwordNotFound
}

class BiometricService {
    private let keychainKey = "com.offlinepwm.masterpassword"
    
    func canUseBiometric() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func getBiometricType() -> String {
        let context = LAContext()
        guard canUseBiometric() else { return "生物识别" }
        
        switch context.biometryType {
        case .faceID:
            return "面容 ID"
        case .touchID:
            return "触控 ID"
        default:
            return "生物识别"
        }
    }
    
    func saveMasterPassword(_ password: String) throws {
        guard canUseBiometric() else {
            throw BiometricError.notAvailable
        }
        
        guard let passwordData = password.data(using: .utf8) else {
            throw BiometricError.keychainError
        }
        
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            nil
        )
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: passwordData,
            kSecAttrAccessControl as String: access as Any
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw BiometricError.keychainError
        }
    }
    
    func retrieveMasterPassword() async throws -> String {
        let context = LAContext()
        context.interactionNotAllowed = false
        
        // 先进行生物识别验证
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "验证以解锁密码本"
            )
            
            guard success else {
                throw BiometricError.authenticationFailed
            }
        } catch {
            throw BiometricError.authenticationFailed
        }
        
        // 验证成功后，从 Keychain 读取密码
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: context
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let passwordData = result as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            throw BiometricError.passwordNotFound
        }
        
        return password
    }
    
    func deleteMasterPassword() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    func hasSavedPassword() -> Bool {
        let context = LAContext()
        context.interactionNotAllowed = true
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: false,
            kSecUseAuthenticationContext as String: context
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess || status == errSecInteractionNotAllowed
    }
}
