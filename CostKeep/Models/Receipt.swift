import Foundation
import FirebaseFirestore

struct Receipt: Identifiable, Codable {
    let id: String
    let date: Date
    let total: Double
    let items: [String]
    let storeName: String
    let currency: String

    init(id: String = UUID().uuidString, date: Date, total: Double, items: [String], storeName: String, currency: String) {
        self.id = id
        self.date = date
        self.total = total
        self.items = items
        self.storeName = storeName
        self.currency = currency
    }
}
