import SwiftUI

enum DisplayMode: String, CaseIterable {
    case system = "跟随系统"
    case light = "浅色模式"
    case dark = "深色模式"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AppFontSize: String, CaseIterable {
    case small = "小"
    case standard = "标准"
    case large = "大"
    
    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .small: return .small
        case .standard: return .large
        case .large: return .xxxLarge
        }
    }
}

enum AppLanguage: String, CaseIterable {
    case system = "跟随系统"
    case zh = "中文"
    case en = "English"
    case ja = "日本語"
    
    var locale: Locale? {
        switch self {
        case .system: return nil
        case .zh: return Locale(identifier: "zh-Hans")
        case .en: return Locale(identifier: "en")
        case .ja: return Locale(identifier: "ja")
        }
    }
}
