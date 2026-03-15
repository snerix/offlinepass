import Foundation

enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    case bank = "金融"
    case account = "账号"
    case doorLock = "门锁"
    case other = "其他"

    var id: String { rawValue }
}

struct PasswordItem: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var account: String = ""
    var value: String
    var note: String = ""
    var category: ItemCategory = .account
    var updateTime: Date = Date()

    init(id: UUID = UUID(), title: String, account: String = "", value: String, note: String = "", category: ItemCategory = .account, updateTime: Date = Date()) {
        self.id = id
        self.title = title
        self.account = account
        self.value = value
        self.note = note
        self.category = category
        self.updateTime = updateTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        account = try container.decodeIfPresent(String.self, forKey: .account) ?? ""
        value = try container.decode(String.self, forKey: .value)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        updateTime = try container.decodeIfPresent(Date.self, forKey: .updateTime) ?? Date()

        let rawCategory = try container.decodeIfPresent(String.self, forKey: .category) ?? "账号"
        switch rawCategory {
        case "一般", "账号":
            category = .account
        case "银行卡", "金融":
            category = .bank
        case "门锁":
            category = .doorLock
        case "其他":
            category = .other
        default:
            category = .account
        }
    }
}
