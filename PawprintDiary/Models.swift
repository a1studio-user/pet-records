import Foundation

enum PetSpecies: String, Codable, CaseIterable, Identifiable, Sendable {
    case cat = "猫"
    case dog = "狗"
    var id: String { rawValue }
    var symbol: String { self == .cat ? "cat.fill" : "dog.fill" }
}

enum PetGender: String, Codable, CaseIterable, Identifiable, Sendable {
    case male = "公"
    case female = "母"
    case unknown = "未知"
    var id: String { rawValue }
}

enum NeuterStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case neutered = "已绝育"
    case notNeutered = "未绝育"
    case unknown = "未知"
    var id: String { rawValue }
}

enum PetAccessRole: String, Codable, Sendable {
    case owner
    case caregiver
}

struct Pet: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var name: String
    var species: PetSpecies
    var gender: PetGender
    var neuterStatus: NeuterStatus
    var breed: String
    var birthday: Date
    var photoData: Data?
    var avatarPath: String? = nil
    var ownerID: UUID? = nil
    var accessRole: PetAccessRole? = nil
    var shareCode: String? = nil
    var modifiedAt: Date? = nil

    var canEditProfile: Bool { accessRole != .caregiver }
    var isSharedWithMe: Bool { accessRole == .caregiver }

    var ageText: String {
        let components = Calendar.current.dateComponents([.year, .month], from: birthday, to: .now)
        return "\(max(0, components.year ?? 0)) 岁 \(max(0, components.month ?? 0)) 个月"
    }
}

struct PetMember: Identifiable, Codable, Hashable, Sendable {
    var id: UUID { userID }
    let userID: UUID
    let displayName: String
    let role: PetAccessRole
    let joinedAt: Date
}

enum RecordKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case deworm = "驱虫"
    case vaccine = "疫苗"
    case food = "主粮"
    case taste = "口味"
    case bath = "洗澡"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .deworm: "pills.fill"
        case .vaccine: "syringe.fill"
        case .food: "takeoutbag.and.cup.and.straw.fill"
        case .taste: "heart.fill"
        case .bath: "shower.fill"
        }
    }
}

enum DewormScope: String, Codable, CaseIterable, Identifiable, Sendable {
    case internalOnly = "内驱"
    case externalOnly = "外驱"
    case both = "内外同驱"
    var id: String { rawValue }
}

struct LifeRecord: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var petID: UUID
    var kind: RecordKind
    var title: String
    var detail: String
    var date: Date
    var price: Double?
    var photoData: Data?
    var reminderDate: Date?
    var frequencyMonths: Int?
    var photoPath: String? = nil
    var dewormScope: DewormScope? = nil
    var vaccineName: String? = nil
    var vaccineDose: Int? = nil
    var packageWeightKG: Double? = nil
    var startedOn: Date? = nil
    var finishedOn: Date? = nil
    var notes: String? = nil
    var modifiedAt: Date? = nil
}

struct TasteEntry: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var petID: UUID
    var brand: String
    var product: String
    var category: String
    var rating: Double
    var date: Date = .now
    var photoData: Data?
    var photoPath: String? = nil
    var modifiedAt: Date? = nil
    var isRedList: Bool { rating >= 3 }
}

struct PendingDeletion: Codable, Hashable, Sendable {
    var kind: RecordKind
    var recordID: UUID
    var petID: UUID? = nil
    var deletedAt: Date? = nil
}

struct CloudDeletion: Hashable, Sendable {
    var kind: RecordKind
    var recordID: UUID
    var petID: UUID
    var deletedAt: Date
}

struct PersistedAppData: Codable {
    var pets: [Pet]
    var records: [LifeRecord]
    var tastes: [TasteEntry]
    var activePetID: UUID?
    var accountEmail: String?
    var pendingDeletions: [PendingDeletion]?
    var cloudUserID: UUID?
}

enum RankingDisplay: String, CaseIterable, Identifiable {
    case list = "列表"
    case gallery = "大图"
    var id: String { rawValue }
}
