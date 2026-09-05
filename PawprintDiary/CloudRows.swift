import Foundation

struct AuthUser: Decodable {
    let id: UUID
    let email: String?
}

struct AuthResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: TimeInterval?
    let expiresAt: TimeInterval?
    let user: AuthUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case expiresAt = "expires_at"
        case user
    }
}

struct PetRow: Codable {
    let id: UUID
    let userID: UUID
    let name: String
    let species: String
    let gender: String
    let neuteredStatus: String
    let breedName: String
    let birthday: String
    let avatarPath: String?
    var updatedAt: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case name
        case species
        case gender
        case neuteredStatus = "neutered_status"
        case breedName = "breed_name"
        case birthday
        case avatarPath = "avatar_path"
        case updatedAt = "updated_at"
    }
}

struct PetShareCodeRow: Decodable {
    let petID: UUID
    let shareCode: String

    enum CodingKeys: String, CodingKey {
        case petID = "pet_id"
        case shareCode = "share_code"
    }
}

struct PetMemberRow: Decodable {
    let userID: UUID
    let displayName: String
    let role: String
    let joinedAt: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case displayName = "display_name"
        case role
        case joinedAt = "joined_at"
    }
}

struct DewormRow: Codable {
    let id: UUID
    let userID: UUID
    let petID: UUID
    let medicineName: String
    let treatmentScope: String
    let purchasePrice: Double?
    let usedAt: String
    let photoPath: String?
    let reminderAt: String?
    let frequencyMonths: Int?
    var updatedAt: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case petID = "pet_id"
        case medicineName = "medicine_name"
        case treatmentScope = "treatment_scope"
        case purchasePrice = "purchase_price"
        case usedAt = "used_at"
        case photoPath = "photo_path"
        case reminderAt = "reminder_at"
        case frequencyMonths = "frequency_months"
        case updatedAt = "updated_at"
    }
}

struct VaccineRow: Codable {
    let id: UUID
    let userID: UUID
    let petID: UUID
    let vaccineName: String
    let injectedAt: String
    let doseNumber: Int
    let photoPath: String?
    let reminderAt: String?
    var updatedAt: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case petID = "pet_id"
        case vaccineName = "vaccine_name"
        case injectedAt = "injected_at"
        case doseNumber = "dose_number"
        case photoPath = "photo_path"
        case reminderAt = "reminder_at"
        case updatedAt = "updated_at"
    }
}

struct FoodRow: Codable {
    let id: UUID
    let userID: UUID
    let petID: UUID
    let productName: String
    let packageWeightKg: Double
    let purchasePrice: Double
    let purchasedOn: String
    let startedOn: String?
    let finishedOn: String?
    let photoPath: String?
    var updatedAt: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case petID = "pet_id"
        case productName = "product_name"
        case packageWeightKg = "package_weight_kg"
        case purchasePrice = "purchase_price"
        case purchasedOn = "purchased_on"
        case startedOn = "started_on"
        case finishedOn = "finished_on"
        case photoPath = "photo_path"
        case updatedAt = "updated_at"
    }
}

struct TasteRow: Codable {
    let id: UUID
    let userID: UUID
    let petID: UUID
    let brandName: String
    let productName: String
    let categoryName: String
    let rating: Double
    let tastedOn: String
    let photoPath: String?
    var updatedAt: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case petID = "pet_id"
        case brandName = "brand_name"
        case productName = "product_name"
        case categoryName = "category_name"
        case rating
        case tastedOn = "tasted_on"
        case photoPath = "photo_path"
        case updatedAt = "updated_at"
    }
}

struct BathRow: Codable {
    let id: UUID
    let userID: UUID
    let petID: UUID
    let bathedAt: String
    let price: Double?
    let notes: String?
    var updatedAt: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case petID = "pet_id"
        case bathedAt = "bathed_at"
        case price
        case notes
        case updatedAt = "updated_at"
    }
}

struct RecordTombstoneRow: Decodable {
    let recordKind: String
    let recordID: UUID
    let petID: UUID
    let deletedAt: String

    enum CodingKeys: String, CodingKey {
        case recordKind = "record_kind"
        case recordID = "record_id"
        case petID = "pet_id"
        case deletedAt = "deleted_at"
    }
}
