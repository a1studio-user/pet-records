import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var newRecordType: RecordKind?
    @State private var showAccount = false
    @State private var showBoundary = false

    private var isExpanded: Bool { AppLayout.isExpanded(horizontalSizeClass) }

    var body: some View {
        ScrollView {
            VStack(spacing: AppLayout.sectionSpacing(horizontalSizeClass)) {
                if let pet = store.activePet {
                    hero(pet)
                    quickActions
                    reminderCard(for: pet)
                    recentRecords(for: pet)
                } else {
                    ContentUnavailableView("先建立宠物档案", systemImage: "pawprint", description: Text("在宠物页面新建档案后即可开始记录。"))
                }
            }
            .adaptivePage()
        }
        .background(AppTheme.cream)
        .navigationTitle("宠刻")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("账号", systemImage: "person.crop.circle") { showAccount = true }.labelStyle(.iconOnly)
                Button("记录边界", systemImage: "checkmark.shield") { showBoundary = true }.labelStyle(.iconOnly)
            }
        }
        .sheet(item: $newRecordType) { AddRecordView(kind: $0) }
        .sheet(isPresented: $showAccount) { AccountView() }
        .alert("仅供记录", isPresented: $showBoundary) {
            Button("我知道了", role: .cancel) {}
        } message: {
            Text("本应用只保存用户主动录入的信息，不提供建议、判断或看法，尤其不提供医疗建议。")
        }
    }

    private func hero(_ pet: Pet) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Menu {
                ForEach(store.pets) { option in
                    Button { store.selectPet(option) } label: {
                        Label(option.name, systemImage: option.id == pet.id ? "checkmark.circle.fill" : option.species.symbol)
                    }
                }
            } label: {
                HStack(spacing: isExpanded ? 19 : 14) {
                    PetAvatar(pet: pet, size: isExpanded ? 98 : 76)
                    VStack(alignment: .leading, spacing: isExpanded ? 7 : 5) {
                        Text("你好呀，\(pet.name)").font(isExpanded ? .largeTitle : .title2).fontWeight(.bold).foregroundStyle(AppTheme.ink)
                        Text("\(pet.breed) · \(pet.gender.rawValue)").font(isExpanded ? .body : .caption).foregroundStyle(AppTheme.secondaryText)
                        Label(pet.ageText, systemImage: "birthday.cake.fill")
                            .font(isExpanded ? .body : .caption).fontWeight(.semibold).foregroundStyle(AppTheme.caramel)
                            .padding(.horizontal, isExpanded ? 12 : 9).padding(.vertical, isExpanded ? 7 : 5)
                            .background(AppTheme.honeySoft, in: Capsule())
                    }
                    Spacer()
                    Image(systemName: "chevron.down").foregroundStyle(AppTheme.secondaryText)
                }
                .roundedCard(radius: isExpanded ? 31 : 27, padding: isExpanded ? 20 : 13)
            }
            .buttonStyle(.plain)

        }
        .padding(.top, 8)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今天记点什么？").font(isExpanded ? .title2 : .headline).fontWeight(isExpanded ? .bold : .regular)
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: isExpanded ? 118 : 92), spacing: isExpanded ? 16 : 10)],
                spacing: isExpanded ? 16 : 10
            ) {
                ForEach(RecordKind.allCases) { kind in
                    Button { newRecordType = kind } label: {
                        VStack(spacing: isExpanded ? 12 : 8) {
                            Image(systemName: kind.symbol).font(isExpanded ? .title : .title3)
                                .frame(width: isExpanded ? 64 : 45, height: isExpanded ? 64 : 45)
                                .background(tileColor(kind), in: RoundedRectangle(cornerRadius: isExpanded ? 21 : 16, style: .continuous))
                            Text(kind.rawValue).font(isExpanded ? .body : .caption).fontWeight(.semibold).foregroundStyle(AppTheme.ink)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, isExpanded ? 18 : 10)
                        .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: isExpanded ? 27 : 21, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func reminderCard(for pet: Pet) -> some View {
        let reminders = store.records(for: pet).filter { ($0.reminderDate ?? .distantPast) > .now }
        VStack(alignment: .leading, spacing: 12) {
            Text("下一件小事").font(isExpanded ? .title2 : .headline).fontWeight(isExpanded ? .bold : .regular)
            if let next = reminders.sorted(by: { $0.reminderDate! < $1.reminderDate! }).first, let date = next.reminderDate {
                HStack(spacing: 14) {
                    VStack(spacing: 1) {
                        Text(date, format: .dateTime.month(.abbreviated)).font(.caption2).fontWeight(.bold)
                        Text(date, format: .dateTime.day()).font(.title2).fontWeight(.bold)
                    }
                    .frame(width: isExpanded ? 68 : 52, height: isExpanded ? 74 : 58).background(AppTheme.paper, in: RoundedRectangle(cornerRadius: isExpanded ? 19 : 15, style: .continuous)).foregroundStyle(AppTheme.caramel)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(pet.name) · 用户设置的记录提醒").font(isExpanded ? .headline : .subheadline).fontWeight(.semibold)
                        Text(next.title).font(isExpanded ? .body : .caption).foregroundStyle(.white.opacity(0.78)).lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "bell.fill").font(isExpanded ? .title2 : .body)
                }
                .padding(isExpanded ? 22 : 17).foregroundStyle(.white)
                .background(LinearGradient(colors: [AppTheme.caramel, AppTheme.ink.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 25, style: .continuous))
            } else {
                Label("暂无用户设置的提醒", systemImage: "bell.slash")
                    .frame(maxWidth: .infinity, alignment: .leading).roundedCard()
            }
        }
    }

    private func recentRecords(for pet: Pet) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text("最近记录").font(isExpanded ? .title2 : .headline).fontWeight(isExpanded ? .bold : .regular); Spacer(); Button("查看全部") { store.selectedTab = 1 }.font(isExpanded ? .body : .caption).fontWeight(.semibold) }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: isExpanded ? 400 : 300), spacing: isExpanded ? 14 : 10)], spacing: isExpanded ? 14 : 10) {
                ForEach(store.records(for: pet).prefix(isExpanded ? 4 : 3)) { RecordRowView(record: $0) }
            }
        }
    }

    private func tileColor(_ kind: RecordKind) -> Color {
        switch kind {
        case .deworm: AppTheme.sageSoft
        case .vaccine: .blue.opacity(0.10)
        case .food: AppTheme.honeySoft
        case .taste: AppTheme.berrySoft
        case .bath: .cyan.opacity(0.11)
        }
    }
}
