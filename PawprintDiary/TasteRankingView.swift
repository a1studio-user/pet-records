import SwiftUI
import UIKit

struct TasteRankingView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var display: RankingDisplay = .gallery
    @State private var showAdd = false

    private var isExpanded: Bool { AppLayout.isExpanded(horizontalSizeClass) }

    var body: some View {
        ScrollView {
            if let pet = store.activePet {
                let all = store.tastes(for: pet)
                let red = all.filter(\.isRedList).sorted { $0.rating > $1.rating }
                let black = all.filter { !$0.isRedList }.sorted { $0.rating < $1.rating }
                VStack(spacing: isExpanded ? 22 : 16) {
                    PetSwitcher(label: "当前宠物")
                    summary(all: all, red: red, black: black)
                    HStack {
                        Text("展示方式").font(isExpanded ? .body : .caption).fontWeight(.semibold).foregroundStyle(AppTheme.secondaryText)
                        Spacer()
                        displaySwitcher
                    }
                    rankingSection(title: "红榜", subtitle: "3 星及以上", entries: red, redList: true)
                    rankingSection(title: "黑榜", subtitle: "3 星以下", entries: black, redList: false)
                }
                .adaptivePage()
            } else {
                ContentUnavailableView("先建立宠物档案", systemImage: "pawprint", description: Text("新建宠物后即可记录口味评分。"))
                    .frame(maxWidth: .infinity, minHeight: 520)
            }
        }
        .background(AppTheme.cream)
        .navigationTitle("口味榜")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("新增口味评分", systemImage: "plus") { showAdd = true }.labelStyle(.iconOnly) } }
        .sheet(isPresented: $showAdd) { AddRecordView(kind: .taste) }
    }

    private func summary(all: [TasteEntry], red: [TasteEntry], black: [TasteEntry]) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack { summaryText(all); Spacer(); badges(red: red, black: black) }
            VStack(alignment: .leading, spacing: 12) {
                summaryText(all)
                badges(red: red, black: black)
            }
        }
        .padding(isExpanded ? 22 : 17).background(AppTheme.berrySoft, in: RoundedRectangle(cornerRadius: isExpanded ? 29 : 25, style: .continuous))
    }

    private func summaryText(_ all: [TasteEntry]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("尝过 \(all.count) 种美味").font(isExpanded ? .title2 : .headline).fontWeight(isExpanded ? .bold : .regular)
            let average = all.isEmpty ? 0 : all.map(\.rating).reduce(0, +) / Double(all.count)
            Text("平均评分 \(average, format: .number.precision(.fractionLength(1))) / 5 · 支持半星")
                .font(isExpanded ? .body : .caption2)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private func badges(red: [TasteEntry], black: [TasteEntry]) -> some View {
        HStack(spacing: 8) {
            badge("红 \(red.count)", red: true)
            badge("黑 \(black.count)", red: false)
        }
    }

    private func badge(_ text: String, red: Bool) -> some View {
        Text(text).font(isExpanded ? .body : .caption).fontWeight(.bold).foregroundStyle(red ? .red.opacity(0.65) : AppTheme.ink.opacity(0.75))
            .padding(.horizontal, isExpanded ? 14 : 10).padding(.vertical, isExpanded ? 9 : 7)
            .background(red ? AppTheme.berrySoft : Color.gray.opacity(0.14), in: Capsule())
    }

    private var displaySwitcher: some View {
        HStack(spacing: 4) {
            ForEach(RankingDisplay.allCases) { option in
                Button {
                    guard display != option else { return }
                    withAnimation(.easeOut(duration: 0.14)) {
                        display = option
                    }
                } label: {
                    Label(option.rawValue, systemImage: option == .list ? "list.bullet" : "square.grid.2x2")
                        .font(isExpanded ? .body : .caption)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: isExpanded ? 44 : 40)
                        .contentShape(Rectangle())
                        .foregroundStyle(display == option ? AppTheme.ink : AppTheme.secondaryText)
                        .background(
                            display == option ? AppTheme.paper : Color.clear,
                            in: RoundedRectangle(cornerRadius: isExpanded ? 14 : 12, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .accessibilityLabel(option.rawValue)
                .accessibilityAddTraits(display == option ? .isSelected : [])
            }
        }
        .padding(4)
        .frame(width: isExpanded ? 230 : 176)
        .background(Color.black.opacity(0.06), in: RoundedRectangle(cornerRadius: isExpanded ? 18 : 16, style: .continuous))
    }

    private func rankingSection(title: String, subtitle: String, entries: [TasteEntry], redList: Bool) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 9) {
                Image(systemName: redList ? "heart.fill" : "circle.fill")
                    .foregroundStyle(redList ? .pink.opacity(0.70) : AppTheme.secondaryText)
                    .frame(width: 34, height: 34).background(redList ? AppTheme.berrySoft : Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(title)  \(entries.count)").font(isExpanded ? .title2 : .headline)
                    Text(subtitle).font(isExpanded ? .caption : .caption2).foregroundStyle(AppTheme.secondaryText)
                }
            }
            if entries.isEmpty {
                Text(redList ? "还没有进入红榜的食物" : "目前没有黑榜记录")
                    .font(.caption).foregroundStyle(AppTheme.secondaryText).frame(maxWidth: .infinity).padding(24)
                    .overlay { RoundedRectangle(cornerRadius: 20).stroke(style: StrokeStyle(lineWidth: 1, dash: [5])) .foregroundStyle(Color.gray.opacity(0.25)) }
            } else if display == .gallery {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(entries) { TasteGalleryCard(entry: $0, redList: redList) }
                }
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(entries) { TasteListCard(entry: $0, redList: redList) }
                }
            }
        }
    }
}

struct TasteGalleryCard: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let entry: TasteEntry
    let redList: Bool
    private var isExpanded: Bool { AppLayout.isExpanded(horizontalSizeClass) }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            tasteImage(height: isExpanded ? 230 : 145)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.product).font(isExpanded ? .title3 : .subheadline).fontWeight(.semibold).lineLimit(1)
                    Text("\(entry.brand) · \(entry.category)").font(isExpanded ? .caption : .caption2).foregroundStyle(AppTheme.secondaryText).lineLimit(1)
                }
                Spacer()
                Text(redList ? "红榜" : "黑榜").font(isExpanded ? .caption : .caption2).fontWeight(.bold).foregroundStyle(redList ? .pink : AppTheme.secondaryText)
            }
            ratingLabel
        }
        .roundedCard(radius: isExpanded ? 30 : 26, padding: isExpanded ? 14 : 10)
    }

    private func tasteImage(height: CGFloat) -> some View {
        Group {
            if let data = entry.photoData, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFill() }
            else { Image(systemName: "takeoutbag.and.cup.and.straw.fill").font(isExpanded ? .system(size: 54) : .largeTitle).foregroundStyle(AppTheme.caramel) }
        }
        .frame(maxWidth: .infinity).frame(height: height).background(AppTheme.honeySoft)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)).clipped()
        .accessibilityLabel(entry.photoData == nil ? "暂无产品照片" : "产品照片")
    }

    private var ratingLabel: some View {
        Label(entry.rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
            .font(isExpanded ? .body : .caption).fontWeight(.semibold).foregroundStyle(AppTheme.honey)
    }
}

struct TasteListCard: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let entry: TasteEntry
    let redList: Bool
    @State private var showPhoto = false
    private var isExpanded: Bool { AppLayout.isExpanded(horizontalSizeClass) }
    var body: some View {
        HStack(spacing: 9) {
            Button {
                if entry.photoData != nil { showPhoto = true }
            } label: {
                ProductPhoto(data: entry.photoData, kind: .taste, size: isExpanded ? 68 : 54)
            }
            .buttonStyle(.plain)
            .disabled(entry.photoData == nil)
            .accessibilityLabel(entry.photoData == nil ? "暂无产品照片" : "查看产品大图")
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.product).font(isExpanded ? .headline : .subheadline).fontWeight(.semibold).lineLimit(1)
                Text("\(entry.brand) · \(entry.category)").font(isExpanded ? .caption : .caption2).foregroundStyle(AppTheme.secondaryText).lineLimit(1)
                Label(entry.rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill").font(isExpanded ? .caption : .caption2).foregroundStyle(AppTheme.honey)
            }
            Spacer()
            Text(redList ? "红榜" : "黑榜").font(isExpanded ? .caption : .caption2).fontWeight(.bold).foregroundStyle(redList ? .pink : AppTheme.secondaryText)
        }
        .roundedCard(radius: isExpanded ? 21 : 17, padding: isExpanded ? 12 : 8)
        .sheet(isPresented: $showPhoto) { PhotoViewer(data: entry.photoData, title: entry.product) }
    }
}
