import Foundation

// Make the type public to ensure it's accessible
public struct ReceiptJSON: Codable {
    public struct Item: Codable {
        public let name: String
        public let price: String
        
        public init(name: String, price: String) {
            self.name = name
            self.price = price
        }
    }
    
    public let date: String
    public let total: String
    public let items: [Item]
    public let storeName: String?
    public let currency: String?
    
    public init(date: String, total: String, items: [Item], storeName: String?, currency: String?) {
        self.date = date
        self.total = total
        self.items = items
        self.storeName = storeName
        self.currency = currency
    }
} 