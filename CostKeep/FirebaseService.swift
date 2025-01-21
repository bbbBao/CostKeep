import FirebaseStorage
import FirebaseFirestore
import FirebaseVertexAI
import UIKit
import FirebaseAuth
import Foundation

@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    private let model = VertexAI.vertexAI().generativeModel(modelName: "gemini-1.5-flash")
    
    private init() {}
    
    // Add this struct definition at the top level of the file, after the class declaration
    struct ReceiptJSON: Codable {
        let date: String
        let total: Double
        let items: [ItemJSON]
        
        struct ItemJSON: Codable {
            let name: String
            let price: Double
        }
    }
    
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
        
        do {
            let decoder = JSONDecoder()
            let receiptJSON = try decoder.decode(ReceiptJSON.self, from: jsonData)
            return try parseReceipt(from: receiptJSON)
        } catch {
            print("JSON Parsing Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func parseReceipt(from json: ReceiptJSON) throws -> Receipt {
        do {
            guard let date = ISO8601DateFormatter().date(from: json.date) else {
                throw NSError(domain: "FirebaseService", code: 6,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid date format"])
            }
            
            let items = json.items.map { "\($0.name): $\(String(format: "%.2f", $0.price))" }
            
            return Receipt(
                id: UUID().uuidString,
                date: date,
                total: json.total,
                items: items,
                storeName: "Unknown Store"
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
        
        try await db.collection("receipts").document(receipt.id).setData([
            "userId": userId,
            "date": receipt.date,
            "total": receipt.total,
            "items": receipt.items,
            "storeName": receipt.storeName
        ])
    }
    
    func fetchReceipts(from startDate: Date = Date.distantPast, 
                       to endDate: Date = Date()) async throws -> [Receipt] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirebaseService", code: 2,
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let snapshot = try await db.collection("receipts")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .whereField("date", isLessThanOrEqualTo: endDate)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            guard let date = data["date"] as? Date,
                  let total = data["total"] as? Double,
                  let items = data["items"] as? [String],
                  let storeName = data["storeName"] as? String else {
                return nil
            }
            return Receipt(
                id: document.documentID,
                date: date,
                total: total,
                items: items,
                storeName: storeName
            )
        }
    }
    
    func processReceipt(_ imageData: Data) async throws -> Receipt {
        // Add your receipt processing logic here
        // This is a placeholder implementation
        return Receipt(
            date: Date(),
            total: 0.0,
            items: [],
            storeName: "Processing..."
        )
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
