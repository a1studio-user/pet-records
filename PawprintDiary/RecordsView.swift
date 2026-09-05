import SwiftUI

struct RecordsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var filter: RecordKind?
    @State private var newRecordType: RecordKind?
    @State private var editingRecord: LifeRecord?
    @State private var pendingDeletion: LifeRecord?
    @State private var openRecordID: UUID?

    private var isExpanded: Bool { AppLayout.isExpanded(horizontalSizeClass) }

    var body: some View {
        VStack(spacing: 0) {
            if let pet = store.activePet {
                PetSwitcher(label: "当前宠物").padding(.horizontal, AppLayout.horizontalPadding(horizontalSizeClass)).padding(.bottom, isExpanded ? 14 : 10)
                Picker("记录分类", selection: $filter) {
                    Text("全部").tag(RecordKind?.none)
                    ForEach(RecordKind.allCases) { Text($0.rawValue).tag(Optional($0)) }
                }
                .pickerStyle(.segmented).padding(.horizontal, AppLayout.horizontalPadding(horizontalSizeClass)).padding(.bottom, isExpanded ? 16 : 12)
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: isExpanded ? 420 : 300), spacing: isExpanded ? 14 : 10)], spacing: isExpanded ? 14 : 10) {
                        let rows = store.records(for: pet, kind: filter)
                        if rows.isEmpty {
                            ContentUnavailableView("这里还是空的", systemImage: "book.closed", description: Text("新增一条记录后会显示在这里。"))
                        } else {
                            ForEach(rows) { record in
                                SwipeRecordRow(
                                    record: record,
                                    openRecordID: $openRecordID,
                                    onEdit: { editingRecord = record },
                                    onDelete: { pendingDeletion = record }
                                )
                            }
                        }
                    }
                    .adaptivePage()
                }
            } else {
                ContentUnavailableView("先建立宠物档案", systemImage: "pawprint", description: Text("新建宠物后即可添加生活记录。"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(AppTheme.cream)
        .navigationTitle("生活记录")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("新增记录", systemImage: "plus") { newRecordType = .deworm }.labelStyle(.iconOnly) } }
        .sheet(item: $newRecordType) { AddRecordView(kind: $0) }
        .sheet(item: $editingRecord) { record in
            AddRecordView(kind: record.kind, record: record, taste: store.tasteEntry(for: record))
        }
        .alert("是否确认删除？", isPresented: deleteConfirmation) {
            Button("取消", role: .cancel) { pendingDeletion = nil }
            Button("删除", role: .destructive) {
                if let pendingDeletion { store.deleteRecord(pendingDeletion) }
                pendingDeletion = nil
            }
        }
        .onChange(of: filter) { _, _ in openRecordID = nil }
    }

    private var deleteConfirmation: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        )
    }
}

private struct SwipeRecordRow: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let record: LifeRecord
    @Binding var openRecordID: UUID?
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var rowOffset: CGFloat = 0
    @State private var isDraggingHorizontally = false

    private var isExpanded: Bool { AppLayout.isExpanded(horizontalSizeClass) }
    private var isOpen: Bool { openRecordID == record.id }
    private var cornerRadius: CGFloat { isExpanded ? 24 : 20 }
    private var actionWidth: CGFloat { isExpanded ? 92 : 74 }
    private var totalActionWidth: CGFloat { actionWidth * 2 }
    private var revealWidth: CGFloat { min(totalActionWidth, max(0, -rowOffset)) }

    var body: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppTheme.paper)

            HStack(spacing: 0) {
                actionButton(title: "编辑", symbol: "pencil", color: .orange) {
                    settle(open: false)
                    onEdit()
                }
                actionButton(title: "删除", symbol: "trash", color: .red) {
                    settle(open: false)
                    onDelete()
                }
            }
            .frame(maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .mask(alignment: .trailing) {
                Rectangle().frame(width: revealWidth)
            }
            .accessibilityHidden(!isOpen)

            RecordRowView(record: record)
                .offset(x: rowOffset)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        if isOpen { settle(open: false) }
                    }
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 15)
                .onChanged { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    isDraggingHorizontally = true
                    let restingOffset = isOpen ? -totalActionWidth : 0
                    rowOffset = min(0, max(-totalActionWidth, restingOffset + value.translation.width))
                }
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else {
                        isDraggingHorizontally = false
                        return
                    }
                    isDraggingHorizontally = false
                    let projectedOffset = rowOffset
                        + value.predictedEndTranslation.width
                        - value.translation.width
                    settle(open: projectedOffset < -totalActionWidth * 0.45)
                }
        )
        .onAppear {
            rowOffset = isOpen ? -totalActionWidth : 0
        }
        .onChange(of: openRecordID) { _, newValue in
            guard !isDraggingHorizontally else { return }
            let targetOffset = newValue == record.id ? -totalActionWidth : 0
            guard abs(rowOffset - targetOffset) > 0.5 else { return }
            withAnimation(.snappy(duration: 0.24)) {
                rowOffset = targetOffset
            }
        }
        .accessibilityAction(named: "编辑记录") {
            settle(open: false)
            onEdit()
        }
        .accessibilityAction(named: "删除记录") {
            settle(open: false)
            onDelete()
        }
    }

    private func settle(open: Bool) {
        withAnimation(.snappy(duration: 0.24)) {
            rowOffset = open ? -totalActionWidth : 0
            openRecordID = open ? record.id : nil
        }
    }

    private func actionButton(
        title: String,
        symbol: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: symbol)
                Text(title).font(.caption).fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(width: actionWidth)
            .frame(maxHeight: .infinity)
            .background(color)
        }
        .buttonStyle(.plain)
        .accessibilityHint(title == "编辑" ? "打开并修改这条记录" : "删除这条记录")
    }
}
