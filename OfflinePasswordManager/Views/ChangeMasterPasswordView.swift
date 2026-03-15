import SwiftUI

struct ChangeMasterPasswordView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("当前密码")) {
                    SecureField("输入当前主密码", text: $oldPassword)
                }
                
                Section(header: Text("新密码")) {
                    SecureField("输入新密码", text: $newPassword)
                    SecureField("确认新密码", text: $confirmPassword)
                    
                    if !newPassword.isEmpty {
                        PasswordStrengthIndicator(password: newPassword)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("密码建议至少 8 位", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(newPassword.count >= 8 ? .green : .gray)
                        Label("包含字母和数字", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(containsLetterAndNumber(newPassword) ? .green : .gray)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: changePassword) {
                        HStack {
                            Spacer()
                            Text("更改密码")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("更改主密码")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("密码已更改", isPresented: $showingSuccess) {
                Button("确定") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("主密码已成功更改，请牢记新密码")
            }
        }
    }
    
    private var isValid: Bool {
        !oldPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }
    
    private func containsLetterAndNumber(_ password: String) -> Bool {
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        return hasLetter && hasNumber
    }
    
    private func changePassword() {
        errorMessage = nil
        
        guard newPassword == confirmPassword else {
            errorMessage = "两次输入的新密码不一致"
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "新密码至少需要 6 位"
            return
        }
        
        do {
            try viewModel.changeMasterPassword(oldPassword: oldPassword, newPassword: newPassword)
            oldPassword = ""
            newPassword = ""
            confirmPassword = ""
            showingSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct PasswordStrengthIndicator: View {
    let password: String
    
    private var strength: PasswordStrength {
        if password.count < 6 {
            return .weak
        } else if password.count < 8 {
            return .medium
        } else if password.count >= 12 && containsSpecialChar(password) {
            return .strong
        } else if password.count >= 10 {
            return .good
        } else {
            return .medium
        }
    }
    
    private func containsSpecialChar(_ password: String) -> Bool {
        let specialChars = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
        return password.rangeOfCharacter(from: specialChars) != nil
    }
    
    var body: some View {
        HStack {
            Text("密码强度:")
                .font(.caption)
                .foregroundColor(.gray)
            
            ForEach(0..<4) { index in
                Rectangle()
                    .fill(index < strength.level ? strength.color : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
            
            Text(strength.text)
                .font(.caption)
                .foregroundColor(strength.color)
        }
    }
}

enum PasswordStrength {
    case weak, medium, good, strong
    
    var level: Int {
        switch self {
        case .weak: return 1
        case .medium: return 2
        case .good: return 3
        case .strong: return 4
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .good: return .blue
        case .strong: return .green
        }
    }
    
    var text: String {
        switch self {
        case .weak: return "弱"
        case .medium: return "中"
        case .good: return "良好"
        case .strong: return "强"
        }
    }
}
