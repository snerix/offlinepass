import SwiftUI
import Combine
import CryptoKit

/// 应用状态枚举
/// 控制应用的三种主要状态
enum AppState {
    case onboarding // 首次使用，需要设置主密码
    case locked     // 已锁定，需要输入密码解锁
    case unlocked   // 已解锁，可以查看和编辑密码
}

/// 应用主视图模型
/// 负责管理应用状态、密码数据和加密逻辑
class AppViewModel: ObservableObject {
    // MARK: - Published Properties（发布属性，UI 会自动响应变化）
    
    /// 应用当前状态
    @Published var state: AppState = .onboarding
    
    /// 密码条目列表（解锁后才有数据）
    @Published var items: [PasswordItem] = []
    
    /// 搜索关键词
    @Published var searchText: String = ""
    
    /// 错误提示信息
    @Published var errorMessage: String?
    
    @Published var biometricEnabled: Bool = false
    
    @Published var filteredItems: [PasswordItem] = []
    
    private var encryptionKey: SymmetricKey?
    private let storage: StorageService
    private let biometric = BiometricService()
    private var lastUnlockTime: Date?
    private let gracePeriodMinutes: TimeInterval = 15 * 60
    private var cancellables = Set<AnyCancellable>()
    
    init(storage: StorageService = StorageService()) {
        self.storage = storage
        self.biometricEnabled = biometric.hasSavedPassword()
        
        Publishers.CombineLatest($items, $searchText)
            .map { items, searchText in
                let result: [PasswordItem]
                if searchText.isEmpty {
                    result = items
                } else {
                    result = items.filter {
                        $0.title.localizedCaseInsensitiveContains(searchText) ||
                        $0.account.localizedCaseInsensitiveContains(searchText)
                    }
                }
                return result.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
            }
            .assign(to: &$filteredItems)
        
        checkState()
    }
    
    func checkState() {
        if storage.hasExistingStore() {
            state = .locked
        } else {
            state = .onboarding
        }
    }
    
    func isWithinGracePeriod() -> Bool {
        guard let lastTime = lastUnlockTime else { return false }
        return Date().timeIntervalSince(lastTime) < gracePeriodMinutes
    }
    
    func shouldAutoLock() -> Bool {
        return !isWithinGracePeriod()
    }
    
    // MARK: - Actions
    
    /// 设置主密码（首次使用）
    /// - Parameter password: 用户输入的主密码
    /// 
    /// 加密流程：
    /// 1. 生成随机盐值（32 字节）
    /// 2. 使用 HKDF-SHA256 从密码和盐值派生 256 位加密密钥
    /// 3. 创建空的密码列表并加密保存
    /// 4. 将盐值和加密数据一起存储到本地文件
    /// 5. 保存加密密钥到内存，切换到解锁状态
    func setupMasterPassword(password: String) {
        do {
            let salt = try SecurityService.generateSalt()
            let key = SecurityService.deriveKey(password: password, salt: salt)
            try storage.save(items: [], key: key, salt: salt)
            self.encryptionKey = key
            self.items = []
            self.state = .unlocked
        } catch {
            self.errorMessage = "初始化失败: \(error.localizedDescription)"
        }
    }
    
    /// 使用密码解锁
    /// - Parameter password: 用户输入的主密码
    /// 
    /// 解密流程：
    /// 1. 从本地文件读取盐值（无需解密）
    /// 2. 使用输入的密码和盐值派生密钥
    /// 3. 尝试解密数据，如果密码正确则成功，否则抛出异常
    /// 4. 解密成功后加载密码列表，进入解锁状态
    func unlock(password: String) {
        // 步骤 1: 读取存储的盐值
        // 盐值是明文存储的，用于派生正确的解密密钥
        guard let salt = storage.getSalt() else {
            self.errorMessage = "数据文件损坏或丢失"
            return
        }
        
        // 步骤 2: 使用相同的算法派生密钥
        // 如果密码正确，派生出的密钥会与加密时的密钥相同
        let key = SecurityService.deriveKey(password: password, salt: salt)
        
        // 步骤 3-4: 尝试解密并加载数据
        do {
            // 使用派生的密钥解密数据
            // AES-GCM 会自动验证数据完整性，如果密钥错误或数据被篡改会抛出异常
            let loadedItems = try storage.load(key: key)
            
            // 解密成功，保存密钥到内存
            self.encryptionKey = key
            self.items = loadedItems
            self.state = .unlocked
            self.lastUnlockTime = Date()
            self.errorMessage = nil
        } catch {
            // 解密失败，可能是密码错误或数据损坏
            self.errorMessage = "密码错误或解密失败"
        }
    }
    
    func lock() {
        self.encryptionKey = nil
        self.items = []
        self.state = .locked
    }
    
    func addItem(_ item: PasswordItem) {
        items.append(item)
        saveData()
    }
    
    func updateItem(_ item: PasswordItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            saveData()
        }
    }
    
    func deleteItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveData()
    }
    
    func delete(item: PasswordItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
            saveData()
        }
    }
    
    /// 保存密码数据到本地（加密）
    /// 
    /// 保存流程：
    /// 1. 检查是否有加密密钥（必须在解锁状态）
    /// 2. 使用当前密钥加密整个密码列表
    /// 3. 将加密数据和盐值一起保存到本地文件
    /// 
    /// 注意：每次修改密码（增删改）都会重新加密整个列表
    private func saveData() {
        // 确保有加密密钥和盐值
        guard let key = encryptionKey, let salt = storage.getSalt() else { return }
        
        do {
            // 将整个密码列表序列化为 JSON
            // 然后使用 AES-256-GCM 加密
            // 最后保存到 Documents/secrets.enc 文件
            try storage.save(items: items, key: key, salt: salt)
        } catch {
            self.errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Biometric Authentication
    
    func canUseBiometric() -> Bool {
        return biometric.canUseBiometric()
    }
    
    func getBiometricType() -> String {
        return biometric.getBiometricType()
    }
    
    func unlockWithBiometric() {
        Task {
            do {
                let password = try await biometric.retrieveMasterPassword()
                
                await MainActor.run {
                    guard let salt = storage.getSalt() else {
                        self.errorMessage = "数据文件损坏或丢失"
                        return
                    }
                    
                    let key = SecurityService.deriveKey(password: password, salt: salt)
                    
                    do {
                        let loadedItems = try storage.load(key: key)
                        self.encryptionKey = key
                        self.items = loadedItems
                        self.state = .unlocked
                        self.lastUnlockTime = Date()
                        self.errorMessage = nil
                    } catch {
                        self.errorMessage = "密码错误或解密失败"
                    }
                }
            } catch BiometricError.authenticationFailed {
                await MainActor.run {
                    self.errorMessage = "生物识别已取消"
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "生物识别失败，请使用密码登录"
                }
            }
        }
    }
    
    func unlockWithBiometricSilent() async -> Bool {
        do {
            let password = try await biometric.retrieveMasterPassword()
            
            return await MainActor.run {
                guard let salt = storage.getSalt() else {
                    return false
                }
                
                let key = SecurityService.deriveKey(password: password, salt: salt)
                
                do {
                    let loadedItems = try storage.load(key: key)
                    self.encryptionKey = key
                    self.items = loadedItems
                    self.state = .unlocked
                    self.lastUnlockTime = Date()
                    self.errorMessage = nil
                    return true
                } catch {
                    return false
                }
            }
        } catch {
            return false
        }
    }
    
    func enableBiometric(password: String) {
        guard canUseBiometric() else {
            self.errorMessage = "设备不支持生物识别"
            return
        }
        
        guard let salt = storage.getSalt() else {
            self.errorMessage = "数据文件损坏"
            return
        }
        
        let key = SecurityService.deriveKey(password: password, salt: salt)
        
        do {
            _ = try storage.load(key: key)
            
            try biometric.saveMasterPassword(password)
            self.biometricEnabled = true
            self.errorMessage = nil
        } catch {
            self.errorMessage = "密码验证失败"
        }
    }
    
    func disableBiometric() {
        biometric.deleteMasterPassword()
        self.biometricEnabled = false
    }
    
    // MARK: - Export/Import
    
    func exportData(password: String) throws -> URL {
        let exportData = try ExportService.exportData(items: items, password: password)
        return try ExportService.createExportURL(data: exportData)
    }
    
    func importData(from url: URL, password: String) throws {
        let fileData = try Data(contentsOf: url)
        let importedItems = try ExportService.importData(from: fileData, password: password)
        
        self.items = importedItems
        saveData()
    }
    
    // MARK: - Change Master Password
    
    func changeMasterPassword(oldPassword: String, newPassword: String) throws {
        guard let oldSalt = storage.getSalt() else {
            throw PasswordChangeError.dataCorrupted
        }
        
        let oldKey = SecurityService.deriveKey(password: oldPassword, salt: oldSalt)
        
        do {
            _ = try storage.load(key: oldKey)
        } catch {
            throw PasswordChangeError.incorrectOldPassword
        }
        
        let newSalt = try SecurityService.generateSalt()
        let newKey = SecurityService.deriveKey(password: newPassword, salt: newSalt)
        
        try storage.save(items: items, key: newKey, salt: newSalt)
        
        self.encryptionKey = newKey
        
        if biometricEnabled {
            try? biometric.saveMasterPassword(newPassword)
        }
    }
}

enum PasswordChangeError: Error, LocalizedError {
    case incorrectOldPassword
    case dataCorrupted
    
    var errorDescription: String? {
        switch self {
        case .incorrectOldPassword:
            return "旧密码错误"
        case .dataCorrupted:
            return "数据文件损坏"
        }
    }
}
