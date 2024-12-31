import FirebaseStorage
import FirebaseFirestore
import FirebaseVertexAI
import UIKit
import FirebaseAuth

class FirebaseService {
    static let shared = FirebaseService()
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    private let model = VertexAI.vertexAI().generativeModel(modelName: "gemini-1.5-flash")
    
    func uploadReceiptImage(_ image: UIImage) async throws -> String {
        let currentUser = Auth.auth().currentUser
        print("Debug - Current User: \(String(describing: currentUser?.uid))")
        print("Debug - Auth State: \(Auth.auth().currentUser != nil ? "Authenticated" : "Not Authenticated")")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirebaseService", code: 2, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            throw NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let filename = "\(UUID().uuidString).jpg"
        let path = "receipts/\(userId)/\(filename)"
        let storageRef = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await storageRef.downloadURL()
            return downloadURL.absoluteString
        } catch {
            print("Firebase Storage Error: \(error.localizedDescription)")
            print("Attempted path: \(path)")
            print("User ID: \(userId)")
            
            if let errorCode = (error as NSError).userInfo["FIRStorageErrorCode"] as? Int,
               errorCode == -13010 { // App Check error code
                throw NSError(domain: "FirebaseService", 
                            code: 3, 
                            userInfo: [NSLocalizedDescriptionKey: "App verification failed. Please try again later."])
            }
            throw error
        }
    }
    
    func processReceiptImage(_ image: UIImage) async throws -> Receipt {
        // Upload image to Firebase Storage
        _ = try await uploadReceiptImage(image)
        
        let prompt = """
        This is a receipt image. Please extract the following information:
        1. Date of purchase
        2. Total amount
        3. List of items with their prices
        Format the response as JSON with the following structure:
        {
            "date": "YYYY-MM-DD",
            "total": 00.00,
            "items": [
                {"name": "item name", "price": 00.00}
            ]
        }
        """
        
        do {
            let response = try await model.generateContent(image, prompt)
            guard let jsonString = response.text else {
                throw NSError(domain: "FirebaseService", code: 4, 
                            userInfo: [NSLocalizedDescriptionKey: "Failed to get response from Vertex AI"])
            }
            
            return try parseReceiptJSON(jsonString)
        } catch {
            print("Vertex AI Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func parseReceiptJSON(_ jsonString: String) throws -> Receipt {
        // Clean up the JSON string to handle potential markdown formatting
        let cleanJSON = jsonString.replacingOccurrences(of: "```json\n", with: "")
            .replacingOccurrences(of: "\n```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanJSON.data(using: .utf8) else {
            throw NSError(domain: "FirebaseService", code: 5,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to convert response to data"])
        }
        
        struct ReceiptJSON: Codable {
            let date: String
            let total: Double
            let items: [ItemJSON]
            
            struct ItemJSON: Codable {
                let name: String
                let price: Double
            }
        }
        
        do {
            let decoder = JSONDecoder()
            let receiptJSON = try decoder.decode(ReceiptJSON.self, from: jsonData)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            guard let date = dateFormatter.date(from: receiptJSON.date) else {
                throw NSError(domain: "FirebaseService", code: 6,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid date format"])
            }
            
            let items = receiptJSON.items.map { "\($0.name): $\(String(format: "%.2f", $0.price))" }
            
            return Receipt(
                date: date,
                total: receiptJSON.total,
                items: items
            )
        } catch {
            print("JSON Parsing Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func saveReceipt(_ receipt: Receipt) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirebaseService", code: 2, 
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await db.collection("receipts").document(receipt.id.uuidString).setData([
            "userId": userId,
            "date": receipt.date,
            "total": receipt.total,
            "items": receipt.items
        ])
    }
    
    func fetchReceipts() async throws -> [Receipt] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirebaseService", code: 2, 
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let snapshot = try await db.collection("receipts")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.map { document in
            let data = document.data()
            let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
            let total = data["total"] as? Double ?? 0.0
            let items = data["items"] as? [String] ?? []
            
            return Receipt(date: date, total: total, items: items)
        }
    }
}

// Add this extension to support multiple date formats
extension DateFormatter {
    var dateFormats: [String] {
        get { return [] }
        set {
            self.locale = Locale(identifier: "en_US_POSIX")
            self.dateFormat = newValue.first
        }
    }
}
