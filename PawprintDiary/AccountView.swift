import AuthenticationServices
import CryptoKit
import Security
import SwiftUI

struct AccountView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let allowsDismiss: Bool
    @State private var currentNonce: String?
    @State private var showSignOutConfirmation = false
    @State private var showSignOutError = false
    @State private var showDeleteConfirmation = false
    @State private var showDeletionAuthorization = false

    init(allowsDismiss: Bool = true) {
        self.allowsDismiss = allowsDismiss
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    if let accountEmail = store.accountEmail {
                        connected(accountEmail)
                    } else {
                        disconnected
                    }
                }
                .padding()
            }
            .background(AppTheme.cream)
            .navigationTitle("账号")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if allowsDismiss {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly)
                    }
                }
            }
            .alert("是否确认删除账号？", isPresented: $showDeleteConfirmation) {
                Button("取消", role: .cancel) {}
                Button("删除账号", role: .destructive) {
                    showDeletionAuthorization = true
                }
            } message: {
                Text("你的账号、主养宠物及其全部记录会被永久删除；共同饲养的宠物不会被删除，只会从你的账号移除。此操作无法撤销。")
            }
            .alert("是否退出当前账号？", isPresented: $showSignOutConfirmation) {
                Button("取消", role: .cancel) {}
                Button("退出", role: .destructive) {
                    Task {
                        if !(await store.signOut()) {
                            showSignOutError = true
                        }
                    }
                }
            } message: {
                Text("退出后将清除本机缓存并返回 Apple 登录页，账号中的宠物与记录不会删除；重新登录同一账号即可恢复。")
            }
            .alert("暂时无法退出", isPresented: $showSignOutError) {
                Button("好", role: .cancel) {}
            } message: {
                Text("请检查网络后重试。为避免丢失尚未保存的记录，当前账号仍保持登录。")
            }
            .sheet(isPresented: $showDeletionAuthorization) {
                deletionAuthorizationSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled(store.isSyncing)
            }
        }
    }

    private var deletionAuthorizationSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(AppTheme.honey)
            Text("再次确认 Apple 账号")
                .font(.title2.bold())
            Text("为安全删除账号并撤销 Apple 登录凭据，请再次使用当前 Apple 账号确认。确认完成后将立即删除，且无法撤销。")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)

            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = []
            } onCompletion: { result in
                handleDeletionAuthorization(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .disabled(store.isSyncing)

            Button("取消") { showDeletionAuthorization = false }
                .frame(maxWidth: .infinity)
                .disabled(store.isSyncing)
        }
        .padding(24)
        .frame(maxWidth: 520)
        .background(AppTheme.cream)
    }

    private var disconnected: some View {
        Group {
            VStack(alignment: .leading, spacing: 10) {
                Label("使用 Apple 登录", systemImage: "apple.logo")
                    .font(.headline)
                    .foregroundStyle(AppTheme.caramel)
                Text("本 App 需要登录后使用。宠物档案、生活记录和照片会绑定到你的账号；重新安装后登录同一 Apple 账号即可恢复。")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(AppTheme.honeySoft, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            SignInWithAppleButton(.continue) { request in
                do {
                    let nonce = try AppleNonce.random()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = AppleNonce.sha256(nonce)
                } catch {
                    store.authMessage = error.localizedDescription
                }
            } onCompletion: { result in
                handleAppleAuthorization(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .disabled(store.isSyncing || !SupabaseConfiguration.isConfigured)
            .accessibilityHint("登录并开始使用宠物记录")

            Text("Apple 可能提供中转邮箱以隐藏真实邮箱。App 以 Apple 账号的唯一标识绑定数据，不根据邮箱文字判断身份；本 App 仅做记录，不提供医疗建议或判断。")
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
                .padding()
                .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            statusMessage

            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("查看隐私政策", systemImage: "hand.raised.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private func connected(_ accountEmail: String) -> some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                Label("当前账号", systemImage: "person.crop.circle.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.caramel)
                Text(accountEmail).font(.subheadline).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(AppTheme.sageSoft, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            Button {
                showSignOutConfirmation = true
            } label: {
                Label("退出当前账号", systemImage: "rectangle.portrait.and.arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(AppTheme.caramel)
            .disabled(store.isSyncing)

            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("查看隐私政策", systemImage: "hand.raised.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Divider().padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 8) {
                Text("删除账号")
                    .font(.headline)
                Text("永久删除当前账号及由你创建的宠物数据。")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                Button("删除账号及数据", role: .destructive) {
                    showDeleteConfirmation = true
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(store.isSyncing)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .roundedCard(radius: 20, padding: 16)
        }
    }

    @ViewBuilder
    private var statusMessage: some View {
        if let authMessage = store.authMessage {
            Text(authMessage)
                .font(.caption)
                .foregroundStyle(AppTheme.caramel)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func handleAppleAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case let .success(authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                store.authMessage = "Apple 登录返回的信息不完整，请重试。"
                return
            }
            let displayName = credential.fullName.flatMap { components -> String? in
                let value = PersonNameComponentsFormatter().string(from: components)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return value.isEmpty ? nil : value
            }
            currentNonce = nil
            Task {
                await store.signInWithApple(idToken: idToken, nonce: nonce, displayName: displayName)
            }
        case let .failure(error):
            currentNonce = nil
            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                return
            }
            store.authMessage = "Apple 登录失败：\(error.localizedDescription)"
        }
    }

    private func handleDeletionAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case let .success(authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let codeData = credential.authorizationCode,
                  let authorizationCode = String(data: codeData, encoding: .utf8),
                  !authorizationCode.isEmpty else {
                store.authMessage = "Apple 未返回删除账号所需的授权码，请重试。"
                return
            }
            Task {
                if await store.deleteAccount(appleAuthorizationCode: authorizationCode) {
                    showDeletionAuthorization = false
                    dismiss()
                }
            }
        case let .failure(error):
            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                return
            }
            store.authMessage = "Apple 账号确认失败：\(error.localizedDescription)"
        }
    }
}

private enum AppleNonce {
    enum Failure: LocalizedError {
        case randomGenerationFailed

        var errorDescription: String? { "无法创建安全的登录请求，请重试。" }
    }

    static func random(length: Int = 32) throws -> String {
        precondition(length > 0)
        let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        result.reserveCapacity(length)
        while result.count < length {
            var bytes = [UInt8](repeating: 0, count: 16)
            guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
                throw Failure.randomGenerationFailed
            }
            for byte in bytes where byte < characters.count {
                result.append(characters[Int(byte)])
                if result.count == length { break }
            }
        }
        return result
    }

    static func sha256(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
