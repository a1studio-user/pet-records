import Foundation

@main
enum CloudRowsRegressionTests {
    static func main() throws {
        let decoder = JSONDecoder()
        let ownerID = "15f0802d-8f56-43c4-9c1b-ef7fba348256"
        let petID = "219f6f2b-cf0c-4df8-8618-cf2f92380cd6"
        let rowID = "319f6f2b-cf0c-4df8-8618-cf2f92380cd6"

        let auth: AuthResponse = try decode("""
        {"access_token":"access","refresh_token":"refresh","expires_in":3600,"expires_at":1800000000,"user":{"id":"\(ownerID)","email":"owner@example.com"}}
        """, using: decoder)
        try require(auth.user?.id.uuidString.lowercased() == ownerID, "auth user id")

        let pets: [PetRow] = try decode("""
        [{"id":"\(petID)","user_id":"\(ownerID)","name":"蓝精灵","species":"cat","gender":"female","neutered_status":"not_neutered","breed_name":"缅因猫","birthday":"2025-06-19","avatar_path":null,"created_at":"2026-09-03T16:43:15.209658+00:00","updated_at":"2026-09-04T04:01:08.252+00:00"}]
        """, using: decoder)
        try require(pets.first?.userID.uuidString.lowercased() == ownerID, "pet user_id")

        let shareCodes: [PetShareCodeRow] = try decode("""
        [{"pet_id":"\(petID)","share_code":"12345678","updated_at":"2026-09-04T04:01:08.252+00:00"}]
        """, using: decoder)
        try require(shareCodes.first?.petID.uuidString.lowercased() == petID, "share code pet_id")

        let members: [PetMemberRow] = try decode("""
        [{"user_id":"\(ownerID)","display_name":"主人","role":"owner","joined_at":"2026-09-04T04:01:08.252+00:00"}]
        """, using: decoder)
        try require(members.first?.userID.uuidString.lowercased() == ownerID, "member user_id")

        let deworm: [DewormRow] = try decode("""
        [{"id":"\(rowID)","user_id":"\(ownerID)","pet_id":"\(petID)","medicine_name":"海乐妙","treatment_scope":"internal","purchase_price":68.0,"used_at":"2026-09-04","photo_path":null,"reminder_at":null,"frequency_months":3,"updated_at":"2026-09-04T04:01:08.252+00:00"}]
        """, using: decoder)
        try require(deworm.first?.petID.uuidString.lowercased() == petID, "deworm pet_id")

        let vaccine: [VaccineRow] = try decode("""
        [{"id":"\(rowID)","user_id":"\(ownerID)","pet_id":"\(petID)","vaccine_name":"猫三联","injected_at":"2026-09-04T04:01:08.252+00:00","dose_number":2,"photo_path":null,"reminder_at":null,"updated_at":"2026-09-04T04:01:08.252+00:00"}]
        """, using: decoder)
        try require(vaccine.first?.userID.uuidString.lowercased() == ownerID, "vaccine user_id")

        let food: [FoodRow] = try decode("""
        [{"id":"\(rowID)","user_id":"\(ownerID)","pet_id":"\(petID)","product_name":"主粮","package_weight_kg":1.5,"purchase_price":129.0,"purchased_on":"2026-09-04","started_on":null,"finished_on":null,"photo_path":null,"updated_at":"2026-09-04T04:01:08.252+00:00"}]
        """, using: decoder)
        try require(food.first?.packageWeightKg == 1.5, "food package_weight_kg")

        let taste: [TasteRow] = try decode("""
        [{"id":"\(rowID)","user_id":"\(ownerID)","pet_id":"\(petID)","brand_name":"品牌","product_name":"产品","category_name":"罐头","rating":4.5,"tasted_on":"2026-09-04","photo_path":null,"updated_at":"2026-09-04T04:01:08.252+00:00"}]
        """, using: decoder)
        try require(taste.first?.rating == 4.5, "taste rating")

        let bath: [BathRow] = try decode("""
        [{"id":"\(rowID)","user_id":"\(ownerID)","pet_id":"\(petID)","bathed_at":"2026-09-04T04:01:08.252+00:00","price":80.0,"notes":"洗护店","updated_at":"2026-09-04T04:01:08.252+00:00"}]
        """, using: decoder)
        try require(bath.first?.price == 80 && bath.first?.notes == "洗护店", "bath fields")

        let tombstones: [RecordTombstoneRow] = try decode("""
        [{"record_kind":"food","record_id":"\(rowID)","pet_id":"\(petID)","user_id":"\(ownerID)","deleted_at":"2026-09-04T04:02:08.252+00:00"}]
        """, using: decoder)
        try require(tombstones.first?.recordID.uuidString.lowercased() == rowID, "tombstone record_id")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let encoded = try encoder.encode(pets[0])
        let object = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        try require(object?["user_id"] != nil && object?["neutered_status"] != nil, "pet encoding keys")
        try require(object?["userID"] == nil && object?["userId"] == nil, "pet encoding has no camel-case id key")

        print("PASS: Supabase auth and all cloud row payloads decode; snake-case encoding remains correct.")
    }

    private static func decode<T: Decodable>(_ json: String, using decoder: JSONDecoder) throws -> T {
        try decoder.decode(T.self, from: Data(json.utf8))
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ label: String) throws {
        guard condition() else { throw TestFailure(label: label) }
    }
}

private struct TestFailure: LocalizedError {
    let label: String
    var errorDescription: String? { "FAIL: \(label)" }
}
