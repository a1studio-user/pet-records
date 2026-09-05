import Foundation
import Security

struct CloudIdentity: Sendable {
    let userID: UUID
    let email: String?
}

struct CloudSnapshot: Sendable {
    var pets: [Pet]
    var records: [LifeRecord]
    var tastes: [TasteEntry]
    var deletions: [CloudDeletion]

    var isEmpty: Bool { pets.isEmpty && records.isEmpty && tastes.isEmpty && deletions.isEmpty }
}

enum CloudServiceError: LocalizedError {
    case notConfigured
    case invalidResponse
    case missingSession
    case api(status: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Supabase 连接信息不完整。"
        case .invalidResponse: "云端返回了无法识别的数据。"
        case .missingSession: "登录状态已失效，请重新登录。"
        case let .api(_, message): message
        }
    }
}

actor SupabaseCloudService {
    static let shared = SupabaseCloudService()

    private let projectURL: URL?
    private let publishableKey: String?
    private var session: StoredSession?

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    private let decoder: JSONDecoder = {
        JSONDecoder()
    }()

    private let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private init() {
        projectURL = SupabaseConfiguration.projectURL
        publishableKey = SupabaseConfiguration.publishableKey
        if let data = SessionVault.load() {
            session = try? JSONDecoder().decode(StoredSession.self, from: data)
        }
    }

    func restoreIdentity() -> CloudIdentity? {
        session.map { CloudIdentity(userID: $0.userID, email: $0.email) }
    }

    func clearLocalSession() {
        session = nil
        SessionVault.clear()
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> CloudIdentity {
        let payload = AppleIDTokenCredentials(provider: "apple", idToken: idToken, nonce: nonce)
        let data = try await request(
            path: "auth/v1/token",
            method: "POST",
            queryItems: [URLQueryItem(name: "grant_type", value: "id_token")],
            body: encoder.encode(payload)
        )
        let response = try decoder.decode(AuthResponse.self, from: data)
        guard let stored = makeSession(from: response) else { throw CloudServiceError.invalidResponse }
        saveSession(stored)
        return CloudIdentity(userID: stored.userID, email: stored.email)
    }

    func updateDisplayName(_ displayName: String) async throws {
        let identity = try await authenticatedIdentity()
        let normalized = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        try await upsert(
            ProfileNameRow(id: identity.userID, displayName: normalized, updatedAt: timestamp(Date())),
            table: "profiles"
        )
    }

    func signOut() async {
        if session != nil {
            _ = try? await request(path: "auth/v1/logout", method: "POST", authenticated: true)
        }
        session = nil
        SessionVault.clear()
    }

    func push(pets: [Pet], records: [LifeRecord], tastes: [TasteEntry]) async throws {
        let identity = try await authenticatedIdentity()
        let now = timestamp(Date())
        let ownerByPetID = Dictionary(uniqueKeysWithValues: pets.map {
            // Editable pets belong to the currently authenticated owner. This also
            // repairs legacy local records that predate account binding.
            ($0.id, $0.canEditProfile ? identity.userID : ($0.ownerID ?? identity.userID))
        })

        try await upsert(
            ProfileRow(
                id: identity.userID,
                onboardingCompleted: true,
                migrationCompletedAt: now,
                lastSyncedAt: now,
                updatedAt: now
            ),
            table: "profiles"
        )

        for pet in pets where pet.canEditProfile {
            try Task.checkCancellation()
            // Create/update the pet before uploading its avatar. The storage policy
            // checks pet membership, which is created by the pet insert trigger.
            let petRow = PetRow(
                id: pet.id,
                userID: identity.userID,
                name: pet.name,
                species: pet.species == .cat ? "cat" : "dog",
                gender: cloudGender(pet.gender),
                neuteredStatus: cloudNeuterStatus(pet.neuterStatus),
                breedName: pet.breed,
                birthday: dateOnly(pet.birthday),
                avatarPath: pet.avatarPath,
                updatedAt: syncTimestamp(pet.modifiedAt)
            )
            try await upsert(petRow, table: "pets")

            let avatarPath = try await uploadedPath(
                data: pet.photoData,
                existingPath: pet.avatarPath,
                path: "\(identity.userID.uuidString.lowercased())/\(pet.id.uuidString.lowercased())/avatar.jpg"
            )
            if avatarPath != pet.avatarPath {
                try await upsert(
                    PetRow(
                        id: petRow.id,
                        userID: petRow.userID,
                        name: petRow.name,
                        species: petRow.species,
                        gender: petRow.gender,
                        neuteredStatus: petRow.neuteredStatus,
                        breedName: petRow.breedName,
                        birthday: petRow.birthday,
                        avatarPath: avatarPath,
                        // The first upsert creates membership so Storage RLS can
                        // accept the avatar. The follow-up path update must be a
                        // strictly newer version or the stale-write trigger will
                        // intentionally ignore it.
                        updatedAt: timestamp(Date())
                    ),
                    table: "pets"
                )
            }
        }

        for record in records where record.kind != .taste {
            try Task.checkCancellation()
            guard let ownerID = ownerByPetID[record.petID] else { continue }
            let photoPath = try await uploadedPath(
                data: record.photoData,
                existingPath: record.photoPath,
                path: "\(identity.userID.uuidString.lowercased())/\(record.petID.uuidString.lowercased())/records/\(record.id.uuidString.lowercased()).jpg"
            )
            switch record.kind {
            case .deworm:
                try await upsert(
                    DewormRow(
                        id: record.id,
                        userID: ownerID,
                        petID: record.petID,
                        medicineName: record.title,
                        treatmentScope: cloudScope(record.dewormScope ?? inferredScope(record.detail)),
                        purchasePrice: record.price,
                        usedAt: dateOnly(record.date),
                        photoPath: photoPath,
                        reminderAt: record.reminderDate.map(timestamp),
                        frequencyMonths: record.frequencyMonths,
                        updatedAt: syncTimestamp(record.modifiedAt)
                    ),
                    table: "deworm_records"
                )
            case .vaccine:
                try await upsert(
                    VaccineRow(
                        id: record.id,
                        userID: ownerID,
                        petID: record.petID,
                        vaccineName: record.vaccineName ?? inferredVaccineName(record.title),
                        injectedAt: timestamp(record.date),
                        doseNumber: record.vaccineDose ?? inferredDose(record.title),
                        photoPath: photoPath,
                        reminderAt: record.reminderDate.map(timestamp),
                        updatedAt: syncTimestamp(record.modifiedAt)
                    ),
                    table: "vaccine_records"
                )
            case .food:
                try await upsert(
                    FoodRow(
                        id: record.id,
                        userID: ownerID,
                        petID: record.petID,
                        productName: record.title,
                        packageWeightKg: record.packageWeightKG ?? inferredWeight(record.detail),
                        purchasePrice: record.price ?? 0,
                        purchasedOn: dateOnly(record.date),
                        startedOn: record.startedOn.map(dateOnly),
                        finishedOn: record.finishedOn.map(dateOnly),
                        photoPath: photoPath,
                        updatedAt: syncTimestamp(record.modifiedAt)
                    ),
                    table: "food_records"
                )
            case .bath:
                try await upsert(
                    BathRow(
                        id: record.id,
                        userID: ownerID,
                        petID: record.petID,
                        bathedAt: timestamp(record.date),
                        price: record.price,
                        notes: record.notes,
                        updatedAt: syncTimestamp(record.modifiedAt)
                    ),
                    table: "bath_records"
                )
            case .taste:
                break
            }
        }

        for taste in tastes {
            try Task.checkCancellation()
            guard let ownerID = ownerByPetID[taste.petID] else { continue }
            let photoPath = try await uploadedPath(
                data: taste.photoData,
                existingPath: taste.photoPath,
                path: "\(identity.userID.uuidString.lowercased())/\(taste.petID.uuidString.lowercased())/tastes/\(taste.id.uuidString.lowercased()).jpg"
            )
            try await upsert(
                TasteRow(
                    id: taste.id,
                    userID: ownerID,
                    petID: taste.petID,
                    brandName: taste.brand,
                    productName: taste.product,
                    categoryName: taste.category,
                    rating: taste.rating,
                    tastedOn: dateOnly(taste.date),
                    photoPath: photoPath,
                    updatedAt: syncTimestamp(taste.modifiedAt)
                ),
                table: "taste_records"
            )
        }
    }

    func pull() async throws -> CloudSnapshot {
        let identity = try await authenticatedIdentity()
        let petRows: [PetRow] = try await fetch(table: "pets", order: "created_at.asc")
        let shareCodeRows: [PetShareCodeRow] = try await fetch(table: "pet_share_codes", order: "updated_at.desc")
        let dewormRows: [DewormRow] = try await fetch(table: "deworm_records", order: "used_at.desc")
        let vaccineRows: [VaccineRow] = try await fetch(table: "vaccine_records", order: "injected_at.desc")
        let foodRows: [FoodRow] = try await fetch(table: "food_records", order: "purchased_on.desc")
        let tasteRows: [TasteRow] = try await fetch(table: "taste_records", order: "tasted_on.desc")
        let bathRows: [BathRow] = try await fetch(table: "bath_records", order: "bathed_at.desc")
        let tombstoneRows: [RecordTombstoneRow] = try await fetch(table: "record_tombstones", order: "deleted_at.desc")

        var photoCache: [String: Data] = [:]
        func photo(_ path: String?) async -> Data? {
            guard let path else { return nil }
            if let cached = photoCache[path] { return cached }
            guard let data = try? await download(path: path) else { return nil }
            photoCache[path] = data
            return data
        }

        let shareCodes = Dictionary(uniqueKeysWithValues: shareCodeRows.map { ($0.petID, $0.shareCode) })
        var pets: [Pet] = []
        for row in petRows {
            guard let birthday = dateOnlyFormatter.date(from: row.birthday) else { continue }
            pets.append(
                Pet(
                    id: row.id,
                    name: row.name,
                    species: row.species == "dog" ? .dog : .cat,
                    gender: localGender(row.gender),
                    neuterStatus: localNeuterStatus(row.neuteredStatus),
                    breed: row.breedName,
                    birthday: birthday,
                    photoData: await photo(row.avatarPath),
                    avatarPath: row.avatarPath,
                    ownerID: row.userID,
                    accessRole: row.userID == identity.userID ? .owner : .caregiver,
                    shareCode: row.userID == identity.userID ? shareCodes[row.id] : nil,
                    modifiedAt: row.updatedAt.flatMap(parseTimestamp)
                )
            )
        }

        var records: [LifeRecord] = []
        for row in dewormRows {
            guard let usedAt = dateOnlyFormatter.date(from: row.usedAt) else { continue }
            let scope = localScope(row.treatmentScope)
            let detail = "\(scope.rawValue) · ¥\((row.purchasePrice ?? 0).formatted(.number.precision(.fractionLength(2))))" + (row.frequencyMonths.map { " · 每 \($0) 月提醒" } ?? "")
            records.append(
                LifeRecord(
                    id: row.id,
                    petID: row.petID,
                    kind: .deworm,
                    title: row.medicineName,
                    detail: detail,
                    date: usedAt,
                    price: row.purchasePrice,
                    photoData: await photo(row.photoPath),
                    reminderDate: row.reminderAt.flatMap(parseTimestamp),
                    frequencyMonths: row.frequencyMonths,
                    photoPath: row.photoPath,
                    dewormScope: scope,
                    modifiedAt: row.updatedAt.flatMap(parseTimestamp)
                )
            )
        }

        for row in vaccineRows {
            guard let injectedAt = parseTimestamp(row.injectedAt) else { continue }
            records.append(
                LifeRecord(
                    id: row.id,
                    petID: row.petID,
                    kind: .vaccine,
                    title: "\(row.vaccineName) · 第 \(row.doseNumber) 针",
                    detail: "已保存注射时间",
                    date: injectedAt,
                    photoData: await photo(row.photoPath),
                    reminderDate: row.reminderAt.flatMap(parseTimestamp),
                    photoPath: row.photoPath,
                    vaccineName: row.vaccineName,
                    vaccineDose: row.doseNumber,
                    modifiedAt: row.updatedAt.flatMap(parseTimestamp)
                )
            )
        }

        for row in foodRows {
            guard let purchasedOn = dateOnlyFormatter.date(from: row.purchasedOn) else { continue }
            let started = row.startedOn.flatMap { dateOnlyFormatter.date(from: $0) }
            let finished = row.finishedOn.flatMap { dateOnlyFormatter.date(from: $0) }
            var detail = "\(row.packageWeightKg.formatted(.number.precision(.fractionLength(0...2)))) kg"
            if let started, let finished {
                let days = max(1, Calendar.current.dateComponents([.day], from: started, to: finished).day.map { $0 + 1 } ?? 1)
                detail += " · 食用了 \(days) 天"
            } else {
                detail += " · 尚未吃完"
            }
            records.append(
                LifeRecord(
                    id: row.id,
                    petID: row.petID,
                    kind: .food,
                    title: row.productName,
                    detail: detail,
                    date: purchasedOn,
                    price: row.purchasePrice,
                    photoData: await photo(row.photoPath),
                    photoPath: row.photoPath,
                    packageWeightKG: row.packageWeightKg,
                    startedOn: started,
                    finishedOn: finished,
                    modifiedAt: row.updatedAt.flatMap(parseTimestamp)
                )
            )
        }

        for row in bathRows {
            guard let bathedAt = parseTimestamp(row.bathedAt) else { continue }
            var details: [String] = []
            if let price = row.price {
                details.append("¥\(price.formatted(.number.precision(.fractionLength(2))))")
            }
            if let notes = row.notes, !notes.isEmpty { details.append(notes) }
            records.append(
                LifeRecord(
                    id: row.id,
                    petID: row.petID,
                    kind: .bath,
                    title: "洗澡",
                    detail: details.isEmpty ? "未填写价格和备注" : details.joined(separator: " · "),
                    date: bathedAt,
                    price: row.price,
                    notes: row.notes,
                    modifiedAt: row.updatedAt.flatMap(parseTimestamp)
                )
            )
        }

        var tastes: [TasteEntry] = []
        for row in tasteRows {
            let tastedOn = dateOnlyFormatter.date(from: row.tastedOn) ?? .now
            let image = await photo(row.photoPath)
            tastes.append(
                TasteEntry(
                    id: row.id,
                    petID: row.petID,
                    brand: row.brandName,
                    product: row.productName,
                    category: row.categoryName,
                    rating: row.rating,
                    date: tastedOn,
                    photoData: image,
                    photoPath: row.photoPath,
                    modifiedAt: row.updatedAt.flatMap(parseTimestamp)
                )
            )
            records.append(
                LifeRecord(
                    id: row.id,
                    petID: row.petID,
                    kind: .taste,
                    title: "\(row.brandName) \(row.productName)",
                    detail: "\(row.categoryName) · \(row.rating.formatted(.number.precision(.fractionLength(1)))) 星",
                    date: tastedOn,
                    photoData: image,
                    photoPath: row.photoPath,
                    modifiedAt: row.updatedAt.flatMap(parseTimestamp)
                )
            )
        }

        records.sort { $0.date > $1.date }
        let deletions = tombstoneRows.compactMap { row -> CloudDeletion? in
            guard let kind = recordKind(from: row.recordKind),
                  let deletedAt = parseTimestamp(row.deletedAt) else { return nil }
            return CloudDeletion(kind: kind, recordID: row.recordID, petID: row.petID, deletedAt: deletedAt)
        }
        return CloudSnapshot(pets: pets, records: records, tastes: tastes, deletions: deletions)
    }

    @discardableResult
    func deleteRecord(kind: RecordKind, id: UUID, petID: UUID, deletedAt: Date) async throws -> Bool {
        let data = try await rpc(
            "delete_pet_record",
            body: encoder.encode(
                DeleteRecordRequest(
                    pRecordKind: cloudRecordKind(kind),
                    pRecordID: id,
                    pPetID: petID,
                    pDeletedAt: timestamp(deletedAt)
                )
            )
        )
        return (try? decoder.decode(Bool.self, from: data)) ?? false
    }

    @discardableResult
    func joinPet(shareCode: String) async throws -> UUID {
        let data = try await rpc(
            "join_pet_by_share_code",
            body: encoder.encode(JoinPetRequest(pShareCode: shareCode))
        )
        guard let value = try? decoder.decode(UUID.self, from: data) else {
            throw CloudServiceError.invalidResponse
        }
        return value
    }

    func resetShareCode(petID: UUID) async throws -> String {
        let data = try await rpc(
            "reset_pet_share_code",
            body: encoder.encode(PetIDRequest(pPetID: petID))
        )
        guard let value = try? decoder.decode(String.self, from: data) else {
            throw CloudServiceError.invalidResponse
        }
        return value
    }

    func ensureShareCode(petID: UUID) async throws -> String {
        let data = try await rpc(
            "ensure_pet_share_code",
            body: encoder.encode(PetIDRequest(pPetID: petID))
        )
        guard let value = try? decoder.decode(String.self, from: data) else {
            throw CloudServiceError.invalidResponse
        }
        return value
    }

    func members(petID: UUID) async throws -> [PetMember] {
        let data = try await rpc(
            "list_pet_members",
            body: encoder.encode(PetIDRequest(pPetID: petID))
        )
        let rows = try decoder.decode([PetMemberRow].self, from: data)
        return rows.compactMap { row in
            guard let joinedAt = parseTimestamp(row.joinedAt) else { return nil }
            return PetMember(
                userID: row.userID,
                displayName: row.displayName,
                role: row.role == "owner" ? .owner : .caregiver,
                joinedAt: joinedAt
            )
        }
    }

    func removeMember(petID: UUID, userID: UUID) async throws {
        _ = try await rpc(
            "remove_pet_member",
            body: encoder.encode(RemovePetMemberRequest(pPetID: petID, pMemberUserID: userID))
        )
    }

    func leaveSharedPet(petID: UUID) async throws {
        _ = try await rpc(
            "leave_shared_pet",
            body: encoder.encode(PetIDRequest(pPetID: petID))
        )
    }

    func deleteAccount(appleAuthorizationCode: String) async throws {
        _ = try await request(
            path: "functions/v1/delete-account",
            method: "POST",
            body: encoder.encode(DeleteAccountRequest(appleAuthorizationCode: appleAuthorizationCode)),
            authenticated: true
        )
        session = nil
        SessionVault.clear()
    }

    private func authenticatedIdentity() async throws -> CloudIdentity {
        _ = try await validAccessToken()
        guard let session else { throw CloudServiceError.missingSession }
        return CloudIdentity(userID: session.userID, email: session.email)
    }

    private func validAccessToken() async throws -> String {
        guard let session else { throw CloudServiceError.missingSession }
        if session.expiresAt > Date().timeIntervalSince1970 + 60 {
            return session.accessToken
        }
        return try await refreshSession().accessToken
    }

    private func refreshSession() async throws -> StoredSession {
        guard let current = session else { throw CloudServiceError.missingSession }
        let body = try encoder.encode(RefreshRequest(refreshToken: current.refreshToken))
        let data = try await request(
            path: "auth/v1/token",
            method: "POST",
            queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            body: body
        )
        let response = try decoder.decode(AuthResponse.self, from: data)
        guard let refreshed = makeSession(from: response) else { throw CloudServiceError.invalidResponse }
        saveSession(refreshed)
        return refreshed
    }

    private func upsert<T: Encodable>(_ value: T, table: String) async throws {
        _ = try await request(
            path: "rest/v1/\(table)",
            method: "POST",
            queryItems: [URLQueryItem(name: "on_conflict", value: "id")],
            body: encoder.encode(value),
            authenticated: true,
            additionalHeaders: ["Prefer": "resolution=merge-duplicates,return=minimal"]
        )
    }

    private func fetch<T: Decodable>(table: String, order: String) async throws -> [T] {
        let data = try await request(
            path: "rest/v1/\(table)",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "order", value: order)
            ],
            authenticated: true
        )
        return try decoder.decode([T].self, from: data)
    }

    private func rpc(_ name: String, body: Data) async throws -> Data {
        try await request(
            path: "rest/v1/rpc/\(name)",
            method: "POST",
            body: body,
            authenticated: true
        )
    }

    private func uploadedPath(data: Data?, existingPath: String?, path: String) async throws -> String? {
        if let existingPath { return existingPath }
        guard let data else { return existingPath }
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        _ = try await request(
            path: "storage/v1/object/pet-media/\(encodedPath)",
            method: "POST",
            body: data,
            authenticated: true,
            contentType: "image/jpeg",
            additionalHeaders: ["x-upsert": "true"]
        )
        return path
    }

    private func download(path: String) async throws -> Data {
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        return try await request(
            path: "storage/v1/object/authenticated/pet-media/\(encodedPath)",
            authenticated: true,
            contentType: nil
        )
    }

    private func request(
        path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: Data? = nil,
        authenticated: Bool = false,
        contentType: String? = "application/json",
        additionalHeaders: [String: String] = [:]
    ) async throws -> Data {
        guard let projectURL, let publishableKey else { throw CloudServiceError.notConfigured }
        guard var components = URLComponents(url: projectURL.appending(path: path), resolvingAgainstBaseURL: false) else {
            throw CloudServiceError.invalidResponse
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else { throw CloudServiceError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 30
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let contentType { request.setValue(contentType, forHTTPHeaderField: "Content-Type") }
        for (key, value) in additionalHeaders { request.setValue(value, forHTTPHeaderField: key) }
        if authenticated { request.setValue("Bearer \(try await validAccessToken())", forHTTPHeaderField: "Authorization") }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CloudServiceError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw CloudServiceError.api(status: http.statusCode, message: apiMessage(from: data, status: http.statusCode))
        }
        return data
    }

    private func apiMessage(from data: Data, status: Int) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for key in ["message", "msg", "error_description", "error", "code"] {
                if let value = object[key] as? String, !value.isEmpty { return value }
            }
        }
        return "云端请求失败（\(status)）。"
    }

    private func makeSession(from response: AuthResponse) -> StoredSession? {
        guard let accessToken = response.accessToken,
              let refreshToken = response.refreshToken,
              let user = response.user else { return nil }
        return StoredSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: response.expiresAt ?? (Date().timeIntervalSince1970 + (response.expiresIn ?? 3600)),
            userID: user.id,
            email: user.email
        )
    }

    private func saveSession(_ newSession: StoredSession) {
        session = newSession
        if let data = try? JSONEncoder().encode(newSession) { SessionVault.save(data) }
    }

    private func dateOnly(_ date: Date) -> String { dateOnlyFormatter.string(from: date) }
    private func timestamp(_ date: Date) -> String { timestampFormatter.string(from: date) }
    private func syncTimestamp(_ date: Date?) -> String {
        timestamp(date ?? Date(timeIntervalSince1970: 0))
    }

    private func parseTimestamp(_ value: String) -> Date? {
        if let date = timestampFormatter.date(from: value) { return date }
        return ISO8601DateFormatter().date(from: value)
    }

    private func cloudGender(_ gender: PetGender) -> String {
        switch gender { case .male: "male"; case .female: "female"; case .unknown: "unknown" }
    }

    private func localGender(_ value: String) -> PetGender {
        switch value { case "male": .male; case "female": .female; default: .unknown }
    }

    private func cloudNeuterStatus(_ status: NeuterStatus) -> String {
        switch status { case .neutered: "neutered"; case .notNeutered: "not_neutered"; case .unknown: "unknown" }
    }

    private func localNeuterStatus(_ value: String) -> NeuterStatus {
        switch value { case "neutered": .neutered; case "not_neutered": .notNeutered; default: .unknown }
    }

    private func cloudScope(_ scope: DewormScope) -> String {
        switch scope { case .internalOnly: "internal"; case .externalOnly: "external"; case .both: "both" }
    }

    private func localScope(_ value: String) -> DewormScope {
        switch value { case "external": .externalOnly; case "both": .both; default: .internalOnly }
    }

    private func cloudRecordKind(_ kind: RecordKind) -> String {
        switch kind {
        case .deworm: "deworm"
        case .vaccine: "vaccine"
        case .food: "food"
        case .taste: "taste"
        case .bath: "bath"
        }
    }

    private func recordKind(from value: String) -> RecordKind? {
        switch value {
        case "deworm": .deworm
        case "vaccine": .vaccine
        case "food": .food
        case "taste": .taste
        case "bath": .bath
        default: nil
        }
    }

    private func inferredScope(_ detail: String) -> DewormScope {
        if detail.contains("内外同驱") { return .both }
        if detail.contains("外驱") { return .externalOnly }
        return .internalOnly
    }

    private func inferredVaccineName(_ title: String) -> String {
        title.components(separatedBy: " · 第").first ?? title
    }

    private func inferredDose(_ title: String) -> Int {
        let digits = title.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return max(1, Int(digits) ?? 1)
    }

    private func inferredWeight(_ detail: String) -> Double {
        detail.split(separator: " ").first.flatMap { Double($0) } ?? 1
    }
}

private struct StoredSession: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: TimeInterval
    let userID: UUID
    let email: String?
}

private struct AppleIDTokenCredentials: Encodable { let provider: String; let idToken: String; let nonce: String }
private struct RefreshRequest: Encodable { let refreshToken: String }
private struct JoinPetRequest: Encodable { let pShareCode: String }
private struct PetIDRequest: Encodable { let pPetID: UUID }
private struct RemovePetMemberRequest: Encodable { let pPetID: UUID; let pMemberUserID: UUID }
private struct DeleteAccountRequest: Encodable { let appleAuthorizationCode: String }
private struct DeleteRecordRequest: Encodable {
    let pRecordKind: String
    let pRecordID: UUID
    let pPetID: UUID
    let pDeletedAt: String
}
private struct ProfileRow: Encodable {
    let id: UUID
    let onboardingCompleted: Bool
    let migrationCompletedAt: String
    let lastSyncedAt: String
    let updatedAt: String
}

private struct ProfileNameRow: Encodable {
    let id: UUID
    let displayName: String
    let updatedAt: String
}

private enum SessionVault {
    private static let service = "com.anto.PawprintDiary.supabase"
    private static let account = "current-session"

    static func load() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else { return nil }
        return item as? Data
    }

    static func save(_ data: Data) {
        clear()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
