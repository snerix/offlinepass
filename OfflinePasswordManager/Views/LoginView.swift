import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("离线密码本")
                .font(.title)
                .bold()
            
            SecureField("输入主密码解锁", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .onSubmit {
                    viewModel.unlock(password: password)
                }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                viewModel.unlock(password: password)
            }) {
                Text("解锁")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            if viewModel.biometricEnabled {
                Button(action: {
                    viewModel.unlockWithBiometric()
                }) {
                    HStack {
                        Image(systemName: "faceid")
                        Text("使用\(viewModel.getBiometricType())解锁")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
}

struct SetupView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var error: String?
    var shouldAutoUnlock: Binding<Bool> = .constant(false)
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("创建主密码")
                .font(.title)
                .bold()
            
            Text("这是您访问数据的唯一凭证\n请务必牢记，丢失无法找回！")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.bottom)
            
            SecureField("设置密码", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            SecureField("确认密码", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                if password.isEmpty {
                    error = "密码不能为空"
                } else if password != confirmPassword {
                    error = "两次输入的密码不一致"
                } else {
                    viewModel.setupMasterPassword(password: password)
                }
            }) {
                Text("开始使用")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
