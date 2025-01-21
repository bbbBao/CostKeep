import Foundation

// Make the type public to ensure it's accessible
public struct ReceiptJSON: Codable {
    public struct Item: Codable {
        public let name: String
        public let price: Double
        
        public init(name: String, price: Double) {
            self.name = name
            self.price = price
        }
    }
    
    public let date: String
    public let total: Double
    public let items: [Item]
    public let storeName: String?
    
    public init(date: String, total: Double, items: [Item], storeName: String?) {
        self.date = date
        self.total = total
        self.items = items
        self.storeName = storeName
    }
} 