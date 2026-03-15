import SwiftUI
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#endif

struct ExportImportView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingPasswordPrompt = false
    @State private var exportPassword = ""
    @State private var importPassword = ""
    @State private var exportURL: URL?
    @State private var alertMessage: String?
    @State private var showingAlert = false
    @State private var isExporting = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("导出数据")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("导出所有密码数据")
                            .font(.headline)
                        Text("数据将使用主密码加密，可在其他设备导入")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {
                        isExporting = true
                        showingPasswordPrompt = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("导出备份文件")
                        }
                    }
                }
                
                Section(header: Text("导入数据")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("从备份文件导入")
                            .font(.headline)
                        Text("需要输入导出时使用的主密码")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {
                        isExporting = false
                        showingImportSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("选择备份文件")
                        }
                    }
                }
                
                Section(header: Text("注意事项")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("备份文件使用 AES-GCM 加密", systemImage: "lock.shield")
                            .font(.caption)
                        Label("导入会覆盖当前所有数据", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Label("请妥善保管备份文件", systemImage: "folder")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("导出/导入")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("输入密码", isPresented: $showingPasswordPrompt) {
                SecureField("主密码", text: isExporting ? $exportPassword : $importPassword)
                Button("取消", role: .cancel) {
                    exportPassword = ""
                    importPassword = ""
                }
                Button("确认") {
                    if isExporting {
                        performExport()
                    } else {
                        performImport()
                    }
                }
            } message: {
                Text(isExporting ? "使用主密码加密导出数据" : "输入备份文件的主密码")
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
            #if os(iOS)
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            #endif
            .fileImporter(
                isPresented: $showingImportSheet,
                allowedContentTypes: [UTType(filenameExtension: "pwmbackup") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        showingPasswordPrompt = true
                        importURL = url
                    }
                case .failure(let error):
                    alertMessage = "文件选择失败: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    @State private var importURL: URL?
    
    private func performExport() {
        do {
            let url = try viewModel.exportData(password: exportPassword)
            exportURL = url
            exportPassword = ""
            showingExportSheet = true
        } catch {
            alertMessage = "导出失败: \(error.localizedDescription)"
            showingAlert = true
            exportPassword = ""
        }
    }
    
    private func performImport() {
        guard let url = importURL else { return }
        
        do {
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                try viewModel.importData(from: url, password: importPassword)
                alertMessage = "导入成功！共导入 \(viewModel.items.count) 条数据"
                showingAlert = true
                importPassword = ""
                importURL = nil
            }
        } catch {
            alertMessage = "导入失败: \(error.localizedDescription)"
            showingAlert = true
            importPassword = ""
        }
    }
}

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
