import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEnableBiometric = false
    @State private var passwordForBiometric = ""
    @State private var showingExportImport = false
    @State private var showingChangePassword = false
    
    @AppStorage("displayMode") private var displayMode: DisplayMode = .system
    @AppStorage("appFontSize") private var appFontSize: AppFontSize = .standard
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .system
    

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("安全")) {
                    Button(action: {
                        showingChangePassword = true
                    }) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.orange)
                            Text("更改主密码")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Section(header: Text("外观与语言")) {
                    Picker("显示模式", selection: $displayMode) {
                        ForEach(DisplayMode.allCases, id: \.self) { mode in
                            Text(LocalizedStringKey(mode.rawValue)).tag(mode)
                        }
                    }
                    
                    Picker("字体大小", selection: $appFontSize) {
                        ForEach(AppFontSize.allCases, id: \.self) { size in
                            Text(LocalizedStringKey(size.rawValue)).tag(size)
                        }
                    }
                    
                    Picker("多语言", selection: $appLanguage) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(LocalizedStringKey(lang.rawValue)).tag(lang)
                        }
                    }
                }
                
                Section(header: Text("数据管理")) {
                    Button(action: {
                        showingExportImport = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down.circle")
                                .foregroundColor(.blue)
                            Text("导出/导入数据")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Section(header: Text("生物识别")) {
                    if viewModel.canUseBiometric() {
                        Toggle(isOn: $viewModel.biometricEnabled) {
                            HStack {
                                Image(systemName: viewModel.biometricEnabled ? "faceid" : "faceid.slash")
                                    .foregroundColor(viewModel.biometricEnabled ? .green : .gray)
                                Text("启用\(viewModel.getBiometricType())")
                            }
                        }
                        .onChange(of: viewModel.biometricEnabled) { newValue in
                            if newValue {
                                showingEnableBiometric = true
                            } else {
                                viewModel.disableBiometric()
                            }
                        }
                        
                        if viewModel.biometricEnabled {
                            Text("已启用，下次登录可使用\(viewModel.getBiometricType())快速解锁")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("启用后可使用\(viewModel.getBiometricType())快速解锁应用")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("设备不支持生物识别")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("2.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("存储方式")
                        Spacer()
                        Text("本地加密")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("开发商")
                        Spacer()
                        Text("南京亘富软件技术有限公司")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    
                    HStack {
                        Text("版权所有")
                        Spacer()
                        Text("© 2026 南京亘富软件技术有限公司")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    
                    Link(destination: URL(string: "https://github.com/snerix/offlinepass")!) {
                        HStack {
                            Text("开源地址")
                            Spacer()
                            Text("GitHub")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("验证主密码", isPresented: $showingEnableBiometric) {
                SecureField("输入主密码", text: $passwordForBiometric)
                Button("取消", role: .cancel) {
                    viewModel.biometricEnabled = false
                    passwordForBiometric = ""
                }
                Button("确认") {
                    viewModel.enableBiometric(password: passwordForBiometric)
                    passwordForBiometric = ""
                }
            } message: {
                Text("需要验证主密码以启用\(viewModel.getBiometricType())")
            }
            .sheet(isPresented: $showingExportImport) {
                ExportImportView(viewModel: viewModel)
                    .preferredColorScheme(displayMode.colorScheme)
                    .dynamicTypeSize(appFontSize.dynamicTypeSize)
                    .environment(\.locale, appLanguage.locale ?? Locale.current)
            }
            .sheet(isPresented: $showingChangePassword) {
                ChangeMasterPasswordView(viewModel: viewModel)
                    .preferredColorScheme(displayMode.colorScheme)
                    .dynamicTypeSize(appFontSize.dynamicTypeSize)
                    .environment(\.locale, appLanguage.locale ?? Locale.current)
            }
        }
        .preferredColorScheme(displayMode.colorScheme)
        .dynamicTypeSize(appFontSize.dynamicTypeSize)
        .environment(\.locale, appLanguage.locale ?? Locale.current)
    }
}
