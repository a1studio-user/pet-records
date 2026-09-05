import SwiftUI

struct PetsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var editingPet: Pet?
    @State private var showNewPet = false
    @State private var showJoinPet = false
    @State private var leavingPet: Pet?

    private var isExpanded: Bool { AppLayout.isExpanded(horizontalSizeClass) }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: isExpanded ? 420 : 300), spacing: isExpanded ? 16 : 12)], spacing: isExpanded ? 16 : 12) {
                ForEach(store.pets) { pet in
                    HStack(spacing: isExpanded ? 16 : 12) {
                        Button { store.selectPet(pet) } label: {
                            HStack(spacing: isExpanded ? 17 : 13) {
                                PetAvatar(pet: pet, size: isExpanded ? 86 : 68)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(pet.name).font(isExpanded ? .title2 : .title3).fontWeight(.bold)
                                    Text("\(pet.breed) · \(pet.gender.rawValue)").font(isExpanded ? .body : .caption).foregroundStyle(AppTheme.secondaryText)
                                    Text("\(pet.neuterStatus.rawValue) · \(pet.ageText)").font(isExpanded ? .caption : .caption2).foregroundStyle(AppTheme.secondaryText)
                                    Label(pet.isSharedWithMe ? "共同饲养" : "主饲养员", systemImage: pet.isSharedWithMe ? "person.2.fill" : "person.crop.circle.badge.checkmark")
                                        .font(.caption2)
                                        .foregroundStyle(pet.isSharedWithMe ? AppTheme.caramel : .green)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        VStack(spacing: 8) {
                            if pet.id == store.activePet?.id { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                            if pet.canEditProfile {
                                Button("编辑") { editingPet = pet }
                                    .font(isExpanded ? .body : .caption)
                                    .fontWeight(.semibold)
                            } else {
                                Button("退出") { leavingPet = pet }
                                    .font(isExpanded ? .body : .caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .roundedCard(radius: isExpanded ? 30 : 26, padding: isExpanded ? 17 : 12)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: isExpanded ? 300 : 145), spacing: 12)], spacing: 12) {
                    Button { showNewPet = true } label: {
                        petAction("新建宠物档案", symbol: "plus")
                    }
                    Button { showJoinPet = true } label: {
                        petAction("使用分享码添加", symbol: "person.2.badge.plus")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.caramel)

                Label("仅保存用户主动录入的生活记录，不提供医疗建议、判断或提醒周期建议。", systemImage: "checkmark.shield")
                    .font(.caption2).foregroundStyle(AppTheme.secondaryText).padding()
            }
            .adaptivePage()
        }
        .background(AppTheme.cream)
        .navigationTitle("宠物档案")
        .sheet(isPresented: $showNewPet) { PetEditorView() }
        .sheet(item: $editingPet) { PetEditorView(pet: $0) }
        .sheet(isPresented: $showJoinPet) { JoinSharedPetView() }
        .confirmationDialog(
            "退出共同饲养？",
            isPresented: Binding(
                get: { leavingPet != nil },
                set: { if !$0 { leavingPet = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("退出共享", role: .destructive) {
                guard let pet = leavingPet else { return }
                Task {
                    _ = await store.leaveSharedPet(pet)
                    leavingPet = nil
                }
            }
            Button("取消", role: .cancel) { leavingPet = nil }
        } message: {
            Text("只会从你的账号移除该宠物，不会删除宠物档案或其他人的记录。")
        }
    }

    private func petAction(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(isExpanded ? .title3 : .subheadline)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, isExpanded ? 25 : 18)
            .background(AppTheme.paper.opacity(0.6), in: RoundedRectangle(cornerRadius: 23, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .stroke(AppTheme.caramel.opacity(0.28), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            }
    }
}

struct JoinSharedPetView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var showAccount = false
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.2.badge.plus")
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.caramel)
                    .frame(width: 86, height: 86)
                    .background(AppTheme.honeySoft, in: RoundedRectangle(cornerRadius: 30, style: .continuous))

                VStack(spacing: 7) {
                    Text("添加共同饲养的宠物")
                        .font(.title2.bold())
                    Text("输入主饲养员提供的八位数字分享码")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                TextField("00000000", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                    .tracking(5)
                    .focused($isFocused)
                    .padding(.vertical, 18)
                    .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .onChange(of: code) { _, value in
                        code = String(value.filter(\.isNumber).prefix(8))
                    }

                if let message = store.sharingMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(AppTheme.caramel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if store.accountEmail == nil {
                    Button("先通过 Apple 登录", systemImage: "apple.logo") { showAccount = true }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                } else {
                    Button {
                        Task {
                            if await store.joinSharedPet(code: code) { dismiss() }
                        }
                    } label: {
                        HStack {
                            if store.isSyncing { ProgressView().tint(.white) }
                            Text(store.isSyncing ? "正在添加…" : "添加宠物")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(code.count != 8 || store.isSyncing)
                }

                Text("加入后可以查看、新增、编辑和删除生活记录；宠物档案及分享权限仍由主饲养员管理。")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(14)
                    .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                Spacer(minLength: 0)
            }
            .frame(maxWidth: 560)
            .padding(22)
            .background(AppTheme.cream)
            .navigationTitle("使用分享码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly)
                }
            }
            .sheet(isPresented: $showAccount) { AccountView() }
            .onAppear {
                store.sharingMessage = nil
                isFocused = store.accountEmail != nil
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(34)
    }
}
