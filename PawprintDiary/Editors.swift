import SwiftUI
import UIKit

struct AddRecordView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let kind: RecordKind
    private let existingRecord: LifeRecord?
    private let existingTaste: TasteEntry?

    @State private var petID: UUID?
    @State private var name = ""
    @State private var brand = ""
    @State private var product = ""
    @State private var category = ""
    @State private var usesCustomCategory = false
    @State private var scope: DewormScope = .internalOnly
    @State private var date = Date.now
    @State private var dose = 1
    @State private var price: Double?
    @State private var weight: Double?
    @State private var purchaseDate = Date.now
    @State private var startDate = Date.now
    @State private var finishDate = Date.now
    @State private var hasStarted = false
    @State private var hasFinished = false
    @State private var rating = 4.5
    @State private var notes = ""
    @State private var photoData: Data?
    @State private var photoChanged = false
    @State private var reminderEnabled = false
    @State private var frequencyMonths = 3
    @State private var showDewormerPicker = false

    init(kind: RecordKind, record: LifeRecord? = nil, taste: TasteEntry? = nil) {
        self.kind = kind
        existingRecord = record
        existingTaste = taste

        _petID = State(initialValue: record?.petID ?? taste?.petID)
        _date = State(initialValue: record?.date ?? taste?.date ?? .now)
        _purchaseDate = State(initialValue: record?.date ?? .now)
        _price = State(initialValue: record?.price)
        _photoData = State(initialValue: taste?.photoData ?? record?.photoData)
        _reminderEnabled = State(initialValue: record?.reminderDate != nil)
        _frequencyMonths = State(initialValue: record?.frequencyMonths ?? 3)

        switch kind {
        case .deworm:
            _name = State(initialValue: record?.title ?? "")
            _scope = State(initialValue: record?.dewormScope ?? Self.scope(from: record?.detail))
        case .vaccine:
            _name = State(initialValue: record?.vaccineName ?? Self.vaccineName(from: record?.title))
            _dose = State(initialValue: record?.vaccineDose ?? Self.dose(from: record?.title))
        case .food:
            _name = State(initialValue: record?.title ?? "")
            if let record {
                _weight = State(initialValue: record.packageWeightKG ?? Self.weight(from: record.detail))
            } else {
                _weight = State(initialValue: nil)
            }
            _startDate = State(initialValue: record?.startedOn ?? .now)
            _finishDate = State(initialValue: record?.finishedOn ?? .now)
            _hasStarted = State(initialValue: record?.startedOn != nil)
            _hasFinished = State(initialValue: record?.finishedOn != nil)
        case .taste:
            let savedCategory = taste?.category ?? Self.category(from: record?.detail)
            _brand = State(initialValue: taste?.brand ?? "")
            _product = State(initialValue: taste?.product ?? "")
            _category = State(initialValue: savedCategory)
            _usesCustomCategory = State(initialValue: !savedCategory.isEmpty && !Self.presetTasteCategories.contains(savedCategory))
            _rating = State(initialValue: taste?.rating ?? Self.rating(from: record?.detail))
        case .bath:
            _notes = State(initialValue: record?.notes ?? "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("记录给谁") {
                    Picker("宠物", selection: $petID) {
                        ForEach(store.pets) { Text($0.name).tag(Optional($0.id)) }
                    }
                }
                fields
                if kind != .bath {
                    Section {
                        PhotoInputSection(imageData: $photoData)
                            .onChange(of: photoData) { oldValue, newValue in
                                if oldValue != newValue { photoChanged = true }
                            }
                    }
                }
                if kind == .deworm { reminderSection }
                Section {
                    Label("仅保存你输入的内容，不根据名称、日期或针次提供建议与判断。", systemImage: "info.circle")
                        .font(.caption).foregroundStyle(AppTheme.secondaryText)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.cream)
            .navigationTitle(existingRecord == nil ? "新增\(kind.rawValue)记录" : "编辑\(kind.rawValue)记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly) }
                ToolbarItem(placement: .confirmationAction) { Button("保存", systemImage: "checkmark") { save() }.labelStyle(.iconOnly).disabled(!isValid) }
            }
            .sheet(isPresented: $showDewormerPicker) {
                DewormerPickerView(species: selectedPet?.species ?? .cat, selectedName: $name, selectedScope: $scope)
            }
            .onAppear { petID = petID ?? store.activePet?.id }
        }
    }

    @ViewBuilder
    private var fields: some View {
        switch kind {
        case .deworm:
            Section("驱虫信息") {
                Button { showDewormerPicker = true } label: {
                    HStack { Text("驱虫药"); Spacer(); Text(name.isEmpty ? "搜索或选择" : name).foregroundStyle(AppTheme.secondaryText).lineLimit(1); Image(systemName: "chevron.right").font(.caption2) }
                }
                Picker("驱虫类型", selection: $scope) { ForEach(DewormScope.allCases) { Text($0.rawValue).tag($0) } }
                DatePicker("使用日期", selection: $date, displayedComponents: .date)
                LabeledContent("购买价格") {
                    HStack(spacing: 5) {
                        TextField("请输入", value: $price, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                        Text("元").foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
        case .vaccine:
            Section("疫苗信息") {
                TextField("疫苗名称", text: $name)
                DatePicker("注射时间", selection: $date)
                Stepper("第 \(dose) 针", value: $dose, in: 1...99)
            }
        case .food:
            Section("主粮信息") {
                TextField("主粮名称", text: $name)
                LabeledContent("单包规格") {
                    HStack(spacing: 5) {
                        TextField("请输入", value: $weight, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                        Text("千克").foregroundStyle(AppTheme.secondaryText)
                    }
                }
                LabeledContent("购买价格") {
                    HStack(spacing: 5) {
                        TextField("请输入", value: $price, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                        Text("元").foregroundStyle(AppTheme.secondaryText)
                    }
                }
                DatePicker("购买日期", selection: $purchaseDate, displayedComponents: .date)
                Toggle("已经开始吃", isOn: $hasStarted)
                if hasStarted { DatePicker("开始吃的日期", selection: $startDate, displayedComponents: .date) }
                Toggle("已经吃完", isOn: $hasFinished)
                if hasFinished { DatePicker("吃完的日期", selection: $finishDate, in: startDate..., displayedComponents: .date) }
            }
        case .taste:
            Section("食物信息") {
                TextField("食物品牌", text: $brand)
                TextField("产品或口味名称", text: $product)
                LabeledContent("类别") {
                    Menu {
                        ForEach(Self.presetTasteCategories, id: \.self) { option in
                            Button {
                                category = option
                                usesCustomCategory = false
                            } label: {
                                Label(option, systemImage: category == option && !usesCustomCategory ? "checkmark" : "circle")
                            }
                        }
                        Button {
                            if Self.presetTasteCategories.contains(category) { category = "" }
                            usesCustomCategory = true
                        } label: {
                            Label("自定义输入", systemImage: usesCustomCategory ? "checkmark" : "square.and.pencil")
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(category.isEmpty ? "请选择" : category)
                                .foregroundStyle(category.isEmpty ? AppTheme.secondaryText : AppTheme.ink)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                        }
                    }
                }
                if usesCustomCategory {
                    TextField("输入自定义类别", text: $category)
                }
            }
            Section("宠物有多喜欢？") { HalfStarRating(rating: $rating) }
            Section {
                Text(rating >= 3 ? "这条记录会进入红榜" : "这条记录会进入黑榜")
                    .font(.caption).fontWeight(.semibold).foregroundStyle(rating >= 3 ? .pink : AppTheme.secondaryText)
            }
        case .bath:
            Section("洗澡信息") {
                DatePicker("洗澡日期", selection: $date, displayedComponents: .date)
                LabeledContent("价格") {
                    HStack(spacing: 5) {
                        TextField("请输入", value: $price, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                        Text("元").foregroundStyle(AppTheme.secondaryText)
                    }
                }
                TextField("备注（可选）", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }
        }
    }

    private var reminderSection: some View {
        Section("下次提醒") {
            Toggle("设置下次驱虫提醒", isOn: $reminderEnabled)
            if reminderEnabled {
                Stepper("每 \(frequencyMonths) 月/次", value: $frequencyMonths, in: 1...120)
                if let next = Calendar.current.date(byAdding: .month, value: frequencyMonths, to: date) {
                    Text("提醒时间：\(next.formatted(date: .long, time: .omitted))")
                        .font(.caption).foregroundStyle(AppTheme.secondaryText)
                }
                Text("频次完全由用户自行设置，App 不推荐或判断周期。")
                    .font(.caption2).foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private var selectedPet: Pet? { store.pets.first { $0.id == petID } }
    private static let presetTasteCategories = ["罐头", "猫条", "冻干", "汤包"]

    private var isValid: Bool {
        guard petID != nil else { return false }
        switch kind {
        case .deworm:
            return !name.trimmingCharacters(in: .whitespaces).isEmpty && price != nil
        case .food:
            return !name.trimmingCharacters(in: .whitespaces).isEmpty
                && weight.map { $0 > 0 } == true
                && price.map { $0 >= 0 } == true
        case .taste: return !brand.trimmingCharacters(in: .whitespaces).isEmpty && !product.trimmingCharacters(in: .whitespaces).isEmpty && !category.trimmingCharacters(in: .whitespaces).isEmpty
        case .vaccine: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case .bath: return price.map { $0 >= 0 } ?? true
        }
    }

    private func save() {
        guard let petID else { return }

        func commit(_ record: LifeRecord) {
            if existingRecord == nil {
                store.addRecord(record)
            } else {
                store.upsertRecord(record)
            }
        }

        switch kind {
        case .deworm:
            guard let price else { return }
            let reminder = reminderEnabled ? Calendar.current.date(byAdding: .month, value: frequencyMonths, to: date) : nil
            let detail = "\(scope.rawValue) · ¥\(price.formatted(.number.precision(.fractionLength(2))))" + (reminderEnabled ? " · 每 \(frequencyMonths) 月提醒" : "")
            commit(LifeRecord(id: existingRecord?.id ?? UUID(), petID: petID, kind: kind, title: name, detail: detail, date: date, price: price, photoData: photoData, reminderDate: reminder, frequencyMonths: reminderEnabled ? frequencyMonths : nil, photoPath: photoChanged ? nil : existingRecord?.photoPath, dewormScope: scope))
        case .vaccine:
            commit(LifeRecord(id: existingRecord?.id ?? UUID(), petID: petID, kind: kind, title: "\(name) · 第 \(dose) 针", detail: "已保存注射时间", date: date, photoData: photoData, photoPath: photoChanged ? nil : existingRecord?.photoPath, vaccineName: name, vaccineDose: dose))
        case .food:
            guard let weight, let price else { return }
            var detail = "\(weight.formatted(.number.precision(.fractionLength(0...2)))) kg"
            if hasStarted && hasFinished {
                let days = max(1, Calendar.current.dateComponents([.day], from: startDate, to: finishDate).day.map { $0 + 1 } ?? 1)
                detail += " · 食用了 \(days) 天"
            } else { detail += " · 尚未吃完" }
            commit(LifeRecord(id: existingRecord?.id ?? UUID(), petID: petID, kind: kind, title: name, detail: detail, date: purchaseDate, price: price, photoData: photoData, photoPath: photoChanged ? nil : existingRecord?.photoPath, packageWeightKG: weight, startedOn: hasStarted ? startDate : nil, finishedOn: hasFinished ? finishDate : nil))
        case .taste:
            let tasteID = existingTaste?.id ?? existingRecord?.id ?? UUID()
            let savedDate = existingTaste?.date ?? existingRecord?.date ?? .now
            let existingPhotoPath = existingTaste?.photoPath ?? existingRecord?.photoPath
            let taste = TasteEntry(id: tasteID, petID: petID, brand: brand, product: product, category: category, rating: rating, date: savedDate, photoData: photoData, photoPath: photoChanged ? nil : existingPhotoPath)
            let record = LifeRecord(id: tasteID, petID: petID, kind: .taste, title: "\(brand) \(product)", detail: "\(category) · \(rating.formatted(.number.precision(.fractionLength(1)))) 星", date: savedDate, photoData: photoData, photoPath: photoChanged ? nil : existingPhotoPath)
            if existingRecord == nil {
                store.addTaste(taste, record: record)
            } else {
                store.upsertTaste(taste, record: record, replacingRecordID: existingRecord?.id, replacingTasteID: existingTaste?.id)
            }
        case .bath:
            let normalizedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            let bathDate = Calendar.current.startOfDay(for: date)
            var details: [String] = []
            if let price {
                details.append("¥\(price.formatted(.number.precision(.fractionLength(2))))")
            }
            if !normalizedNotes.isEmpty { details.append(normalizedNotes) }
            commit(
                LifeRecord(
                    id: existingRecord?.id ?? UUID(),
                    petID: petID,
                    kind: .bath,
                    title: "洗澡",
                    detail: details.isEmpty ? "未填写价格和备注" : details.joined(separator: " · "),
                    date: bathDate,
                    price: price,
                    notes: normalizedNotes.isEmpty ? nil : normalizedNotes
                )
            )
        }
        dismiss()
    }

    private static func scope(from detail: String?) -> DewormScope {
        guard let detail else { return .internalOnly }
        if detail.contains("内外同驱") { return .both }
        if detail.contains("外驱") { return .externalOnly }
        return .internalOnly
    }

    private static func vaccineName(from title: String?) -> String {
        guard let title else { return "" }
        return title.components(separatedBy: " · 第").first ?? title
    }

    private static func dose(from title: String?) -> Int {
        guard let title else { return 1 }
        let digits = title.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return max(1, Int(digits) ?? 1)
    }

    private static func weight(from detail: String?) -> Double {
        guard let detail else { return 1.5 }
        return detail.split(separator: " ").first.flatMap { Double($0) } ?? 1.5
    }

    private static func category(from detail: String?) -> String {
        detail?.components(separatedBy: " · ").first ?? ""
    }

    private static func rating(from detail: String?) -> Double {
        guard let detail else { return 4.5 }
        let components = detail.components(separatedBy: " · ")
        guard components.count > 1 else { return 4.5 }
        return Double(components[1].components(separatedBy: " ").first ?? "") ?? 4.5
    }
}

struct DewormerPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let species: PetSpecies
    @Binding var selectedName: String
    @Binding var selectedScope: DewormScope
    @State private var search = ""
    @State private var scopeFilter: DewormScope?
    @State private var customName = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("类型", selection: $scopeFilter) {
                        Text("全部").tag(DewormScope?.none)
                        ForEach(DewormScope.allCases) { Text($0.rawValue).tag(Optional($0)) }
                    }.pickerStyle(.segmented)
                }
                Section("\(species.rawValue)用驱虫药") {
                    ForEach(filtered) { drug in
                        Button {
                            selectedName = drug.name; selectedScope = drug.scope; dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 3) { Text(drug.name); Text(drug.scope.rawValue).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                }
                Section("自定义添加") {
                    TextField("药名（简称）", text: $customName)
                    Button("使用这个名称") { selectedName = customName.trimmingCharacters(in: .whitespaces); dismiss() }.disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .searchable(text: $search, prompt: "搜索药名或简称")
            .navigationTitle("选择驱虫药")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly) } }
            .safeAreaInset(edge: .bottom) {
                Text("名称仅用于检索与记录，不构成使用建议。")
                    .font(.caption2).foregroundStyle(AppTheme.secondaryText).padding(10).frame(maxWidth: .infinity).background(.regularMaterial)
            }
        }
    }

    private var filtered: [SeedData.Dewormer] {
        SeedData.dewormers.filter { drug in
            drug.species.contains(species) && (scopeFilter == nil || drug.scope == scopeFilter) && (search.isEmpty || drug.name.localizedCaseInsensitiveContains(search))
        }
    }
}

struct PetEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    private let originalID: UUID?
    @State private var name: String
    @State private var species: PetSpecies
    @State private var gender: PetGender
    @State private var neuterStatus: NeuterStatus
    @State private var breed: String
    @State private var birthday: Date
    @State private var photoData: Data?
    @State private var avatarPath: String?
    @State private var showBreedPicker = false
    @State private var showSharingManager = false

    init(pet: Pet? = nil) {
        originalID = pet?.id
        _name = State(initialValue: pet?.name ?? "")
        _species = State(initialValue: pet?.species ?? .cat)
        _gender = State(initialValue: pet?.gender ?? .unknown)
        _neuterStatus = State(initialValue: pet?.neuterStatus ?? .unknown)
        _breed = State(initialValue: pet?.breed ?? "")
        _birthday = State(initialValue: pet?.birthday ?? .now)
        _photoData = State(initialValue: pet?.photoData)
        _avatarPath = State(initialValue: pet?.avatarPath)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("宠物名称", text: $name)
                    Picker("种类", selection: $species) { ForEach(PetSpecies.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
                    Picker("性别", selection: $gender) { ForEach(PetGender.allCases) { Text($0.rawValue).tag($0) } }
                    Picker("绝育状态", selection: $neuterStatus) { ForEach(NeuterStatus.allCases) { Text($0.rawValue).tag($0) } }
                    Button { showBreedPicker = true } label: { HStack { Text("品种"); Spacer(); Text(breed.isEmpty ? "搜索或选择" : breed).foregroundStyle(.secondary); Image(systemName: "chevron.right").font(.caption2) } }
                    DatePicker("生日", selection: $birthday, in: ...Date.now, displayedComponents: .date)
                }
                Section {
                    PhotoInputSection(imageData: $photoData)
                        .onChange(of: photoData) { oldValue, newValue in
                            if oldValue != newValue { avatarPath = nil }
                        }
                }
                if let pet = currentPet, pet.canEditProfile {
                    Section {
                        if store.accountEmail == nil {
                            Label("登录后自动生成分享码", systemImage: "icloud.slash")
                                .foregroundStyle(AppTheme.secondaryText)
                        } else if let code = pet.shareCode {
                            HStack {
                                Text("分享码")
                                Spacer()
                                Text(formatted(code))
                                    .font(.system(.title3, design: .monospaced, weight: .bold))
                                    .foregroundStyle(AppTheme.caramel)
                                    .accessibilityLabel("分享码 \(code)")
                            }
                            Button("管理分享与共同饲养员", systemImage: "person.2.fill") {
                                showSharingManager = true
                            }
                        } else {
                            Label("分享码生成中", systemImage: "ellipsis.circle")
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    } header: {
                        Text("宠物分享码")
                    } footer: {
                        Text("只有主饲养员能查看和分享此代码。")
                    }
                } else if originalID == nil {
                    Section("宠物分享码") {
                        Label("保存宠物后将自动生成唯一的八位数字分享码", systemImage: "number.square")
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .scrollContentBackground(.hidden).background(AppTheme.cream)
            .navigationTitle(originalID == nil ? "新建宠物档案" : "编辑宠物档案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly) }
                ToolbarItem(placement: .confirmationAction) { Button("保存", systemImage: "checkmark") { save() }.labelStyle(.iconOnly).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || breed.isEmpty) }
            }
            .sheet(isPresented: $showBreedPicker) { BreedPickerView(species: species, selection: $breed) }
            .sheet(isPresented: $showSharingManager) {
                if let originalID { PetSharingView(petID: originalID) }
            }
            .onChange(of: species) { _, _ in breed = "" }
        }
    }

    private func save() {
        store.upsertPet(Pet(id: originalID ?? UUID(), name: name.trimmingCharacters(in: .whitespaces), species: species, gender: gender, neuterStatus: neuterStatus, breed: breed, birthday: birthday, photoData: photoData, avatarPath: avatarPath))
        dismiss()
    }

    private var currentPet: Pet? {
        guard let originalID else { return nil }
        return store.pets.first(where: { $0.id == originalID })
    }

    private func formatted(_ code: String) -> String {
        guard code.count == 8 else { return code }
        let midpoint = code.index(code.startIndex, offsetBy: 4)
        return "\(code[..<midpoint]) \(code[midpoint...])"
    }
}

struct BreedPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let species: PetSpecies
    @Binding var selection: String
    @State private var search = ""
    @State private var customBreed = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(filtered, id: \.self) { breed in
                        Button { selection = breed; dismiss() } label: {
                            HStack {
                                Text(breed)
                                Spacer()
                                if selection == breed { Image(systemName: "checkmark") }
                            }
                        }
                    }
                }

                Section("自定义品种") {
                    TextField("输入品种名称", text: $customBreed)
                    Button {
                        selection = trimmedCustomBreed
                        dismiss()
                    } label: {
                        Label("使用此名称", systemImage: "checkmark.circle")
                    }
                    .disabled(trimmedCustomBreed.isEmpty)
                }
            }
            .searchable(text: $search, prompt: "按中国大陆常用名称搜索")
            .navigationTitle("选择\(species.rawValue)的品种")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly) } }
            .safeAreaInset(edge: .bottom) { Text("不确定、混种或流浪宠物可以选择“其它”，也可以输入自定义品种。").font(.caption2).foregroundStyle(AppTheme.secondaryText).padding(10).frame(maxWidth: .infinity).background(.regularMaterial) }
        }
    }

    private var trimmedCustomBreed: String {
        customBreed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filtered: [String] {
        let source = species == .cat ? SeedData.catBreeds : SeedData.dogBreeds
        return search.isEmpty ? source : source.filter { $0.localizedCaseInsensitiveContains(search) }
    }
}

struct PetSharingView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let petID: UUID
    @State private var members: [PetMember] = []
    @State private var isLoadingMembers = true
    @State private var confirmReset = false
    @State private var memberToRemove: PetMember?

    private var pet: Pet? { store.pets.first(where: { $0.id == petID }) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let pet, let code = pet.shareCode {
                        VStack(spacing: 12) {
                            Text("宠物分享码")
                                .font(.headline)
                            Text(formatted(code))
                                .font(.system(size: 34, weight: .bold, design: .monospaced))
                                .tracking(3)
                                .foregroundStyle(AppTheme.caramel)
                                .accessibilityLabel("分享码 \(code)")
                            Text("将此代码提供给共同饲养员。对方通过 Apple 登录后即可加入 \(pet.name) 的共同记录。")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                                .multilineTextAlignment(.center)
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 12) { shareActions(code: code, petName: pet.name) }
                                VStack(spacing: 10) { shareActions(code: code, petName: pet.name) }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .roundedCard(radius: 26, padding: 20)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("共同饲养员")
                                    .font(.headline)
                                Spacer()
                                if isLoadingMembers { ProgressView() }
                            }
                            ForEach(members) { member in
                                HStack(spacing: 12) {
                                    Image(systemName: member.role == .owner ? "person.crop.circle.badge.checkmark" : "person.crop.circle")
                                        .font(.title2)
                                        .foregroundStyle(member.role == .owner ? .green : AppTheme.caramel)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(member.displayName).font(.subheadline.weight(.semibold))
                                        Text(member.role == .owner ? "主饲养员" : "共同饲养员")
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                    Spacer()
                                    if member.role == .caregiver {
                                        Button("移除", role: .destructive) { memberToRemove = member }
                                            .font(.caption.weight(.semibold))
                                    }
                                }
                                if member.id != members.last?.id { Divider() }
                            }
                            if !isLoadingMembers && members.isEmpty {
                                Text("暂无共同饲养员")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                        .roundedCard(radius: 24, padding: 18)

                        Button("重新生成分享码", systemImage: "arrow.clockwise") { confirmReset = true }
                            .buttonStyle(.bordered)
                            .controlSize(.large)

                        if let message = store.sharingMessage {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(AppTheme.caramel)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        ContentUnavailableView("分享码尚未生成", systemImage: "number.square", description: Text("请保持网络连接并稍后重试。"))
                    }
                }
                .adaptivePage()
                .padding(.top, 12)
            }
            .background(AppTheme.cream)
            .navigationTitle("分享与成员")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly)
                }
            }
            .task { await refreshMembers() }
            .confirmationDialog("重新生成分享码？", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("重新生成", role: .destructive) {
                    guard let pet else { return }
                    Task {
                        if await store.resetShareCode(for: pet) { await refreshMembers() }
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("旧分享码会立即失效，现有共同饲养员不会被移除。")
            }
            .confirmationDialog(
                "移除共同饲养员？",
                isPresented: Binding(
                    get: { memberToRemove != nil },
                    set: { if !$0 { memberToRemove = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("移除", role: .destructive) {
                    guard let member = memberToRemove, let pet else { return }
                    Task {
                        if await store.removeMember(member, from: pet) { await refreshMembers() }
                        memberToRemove = nil
                    }
                }
                Button("取消", role: .cancel) { memberToRemove = nil }
            } message: {
                Text("对方将无法继续查看或记录这只宠物，已有记录会保留。")
            }
        }
    }

    @ViewBuilder
    private func shareActions(code: String, petName: String) -> some View {
        Button("复制分享码", systemImage: "doc.on.doc") {
            UIPasteboard.general.string = code
            store.sharingMessage = "分享码已复制。"
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)

        ShareLink(
            item: "我邀请你共同记录 \(petName)。打开宠刻并输入分享码：\(code)",
            subject: Text("\(petName)的宠物分享码")
        ) {
            Label("分享", systemImage: "square.and.arrow.up")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
    }

    private func refreshMembers() async {
        guard let pet else { return }
        isLoadingMembers = true
        members = await store.members(for: pet)
        isLoadingMembers = false
    }

    private func formatted(_ code: String) -> String {
        guard code.count == 8 else { return code }
        let midpoint = code.index(code.startIndex, offsetBy: 4)
        return "\(code[..<midpoint]) \(code[midpoint...])"
    }
}
