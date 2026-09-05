import SwiftUI

struct RootTabView: View {
    @Environment(AppStore.self) private var store
    @State private var showTypePicker = false
    @State private var pendingRecordType: RecordKind?
    @State private var newRecordType: RecordKind?

    var body: some View {
        TabView(selection: Binding(get: { store.selectedTab }, set: { store.selectedTab = $0 })) {
            NavigationStack { HomeView() }
                .tabItem { Label("首页", systemImage: "house") }.tag(0)
            NavigationStack { RecordsView() }
                .tabItem { Label("记录", systemImage: "book.closed") }.tag(1)
            Color.clear
                .tabItem { Label("新增", systemImage: "plus.circle.fill") }.tag(2)
            NavigationStack { TasteRankingView() }
                .tabItem { Label("口味榜", systemImage: "star") }.tag(3)
            NavigationStack { PetsView() }
                .tabItem { Label("宠物", systemImage: "pawprint") }.tag(4)
        }
        // Only the decorative background reaches the screen edges. NavigationStack,
        // toolbars, tabs and page content continue to honor every device safe area.
        .background(AppTheme.cream.ignoresSafeArea())
        .onAppear {
#if DEBUG
            if store.selectedTab == 2,
               ProcessInfo.processInfo.arguments.contains("--ui-test-sample-data") {
                store.selectedTab = 0
                showTypePicker = true
            }
#endif
        }
        .onChange(of: store.selectedTab) { _, value in
            if value == 2 {
                showTypePicker = true
                store.selectedTab = 0
            }
        }
        .sheet(isPresented: $showTypePicker, onDismiss: openPendingRecord) {
            AddRecordTypeSheet { kind in
                pendingRecordType = kind
                showTypePicker = false
            }
        }
        .sheet(item: $newRecordType) { type in
            AddRecordView(kind: type)
        }
    }

    private func openPendingRecord() {
        guard let kind = pendingRecordType else { return }
        pendingRecordType = nil
        DispatchQueue.main.async { newRecordType = kind }
    }
}

struct AddRecordTypeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let onSelect: (RecordKind) -> Void

    private var isExpanded: Bool { AppLayout.isExpanded(horizontalSizeClass) }
    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: isExpanded ? 18 : 12), GridItem(.flexible(), spacing: isExpanded ? 18 : 12)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: isExpanded ? 26 : 20) {
                HStack {
                    Text("新增一条记录")
                        .font(isExpanded ? .largeTitle : .title2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Button("关闭", systemImage: "xmark") { dismiss() }
                        .labelStyle(.iconOnly)
                        .font(isExpanded ? .title2 : .title3)
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(width: isExpanded ? 54 : 46, height: isExpanded ? 54 : 46)
                        .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: isExpanded ? 19 : 16, style: .continuous))
                }

                LazyVGrid(columns: columns, spacing: isExpanded ? 18 : 12) {
                    ForEach(RecordKind.allCases) { kind in
                        Button { onSelect(kind) } label: {
                            VStack(alignment: .leading, spacing: isExpanded ? 18 : 14) {
                                Image(systemName: kind.symbol)
                                    .font(isExpanded ? .title : .title2)
                                    .foregroundStyle(iconColor(for: kind))
                                    .frame(width: isExpanded ? 64 : 54, height: isExpanded ? 64 : 54)
                                    .background(tileColor(for: kind), in: RoundedRectangle(cornerRadius: isExpanded ? 23 : 19, style: .continuous))
                                Text(title(for: kind))
                                    .font(isExpanded ? .title2 : .headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppTheme.ink)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity, minHeight: isExpanded ? 154 : 126, alignment: .leading)
                            .padding(isExpanded ? 22 : 17)
                            .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: isExpanded ? 30 : 25, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: isExpanded ? 30 : 25, style: .continuous)
                                    .stroke(AppTheme.caramel.opacity(0.18), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("从底部打开新增\(title(for: kind))表单")
                    }
                }
            }
            .frame(maxWidth: isExpanded ? 760 : .infinity)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppLayout.horizontalPadding(horizontalSizeClass))
            .padding(.top, isExpanded ? 12 : 6)
            .padding(.bottom, 14)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.cream)
        .presentationDetents(screenshotPresentationDetents)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(isExpanded ? 40 : 34)
        .presentationBackground(AppTheme.cream)
        .presentationContentInteraction(.scrolls)
    }

    private func title(for kind: RecordKind) -> String {
        kind == .taste ? "口味评分" : "\(kind.rawValue)记录"
    }

    private var screenshotPresentationDetents: Set<PresentationDetent> {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-test-expanded-add-sheet") {
            return [.large]
        }
#endif
        return [.fraction(isExpanded ? 0.50 : 0.58), .large]
    }

    private func tileColor(for kind: RecordKind) -> Color {
        switch kind {
        case .deworm: AppTheme.sageSoft
        case .vaccine: Color.blue.opacity(0.10)
        case .food: AppTheme.honeySoft
        case .taste: AppTheme.berrySoft
        case .bath: Color.cyan.opacity(0.11)
        }
    }

    private func iconColor(for kind: RecordKind) -> Color {
        switch kind {
        case .deworm: .green.opacity(0.62)
        case .vaccine: .blue.opacity(0.58)
        case .food: AppTheme.caramel
        case .taste: .pink.opacity(0.68)
        case .bath: .cyan.opacity(0.72)
        }
    }
}
