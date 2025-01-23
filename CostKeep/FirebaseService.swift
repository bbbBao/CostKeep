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
        let storeName: String
        let date: String
        let total: String
        let currency: String?
        let items: [ItemJSON]
        
        struct ItemJSON: Codable {
            let name: String
            let price: String
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
        // First upload the image and get URL
        let imageURL = try await uploadReceiptImage(image)
        
        // Process receipt with Vertex AI
        let prompt = """
        This is a receipt image. Please extract the following information:
        1. Store name (if not clear, use "Unknown Shop")
        2. Date and time of purchase (format as YYYY-MM-DD HH:mm, for example 2024-03-21 14:30)
        3. Total amount (as string, for example "1550")
        4. Currency symbol (e.g., "$", "¥", "€", "£")
           - If currency symbol is not visible, guess based on the receipt's language. For example:
           - Japanese text → "¥"
           - English text (US) → "$"
           - English text (UK) → "£"
           - European languages → "€"
        5. List of items with their prices (prices as strings)
        Format the response as JSON with the following structure:
        {
            "storeName": "Store Name",
            "date": "YYYY-MM-DD HH:mm",
            "total": "00.00",
            "currency": "¥",
            "items": [
                {"name": "item name", "price": "00.00"}
            ]
        }
        Note: All numeric values should be strings enclosed in quotes.
        """
        
        do {
            let response = try await model.generateContent(image, prompt)
            guard let jsonString = response.text else {
                throw NSError(domain: "FirebaseService", code: 4, 
                            userInfo: [NSLocalizedDescriptionKey: "Failed to get response from Vertex AI"])
            }
            
            // Add debug logging
            print("Debug - Gemini Raw Response:")
            print(jsonString)
            print("Debug - End of Gemini Response")
            
            var receipt = try parseReceiptJSON(jsonString)
            receipt = Receipt(id: receipt.id,
                             date: receipt.date,
                             total: receipt.total,
                             items: receipt.items,
                             storeName: receipt.storeName,
                             currency: receipt.currency,
                             imageURL: imageURL)
            return receipt
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
            // Try multiple date format parsers
            let iso8601Formatter = ISO8601DateFormatter()
            
            let ymdhmFormatter = DateFormatter()
            ymdhmFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            
            let mdyhmFormatter = DateFormatter()
            mdyhmFormatter.dateFormat = "MM/dd/yyyy HH:mm"
            
            let dmyhmFormatter = DateFormatter()
            dmyhmFormatter.dateFormat = "dd/MM/yyyy HH:mm"
            
            let formatters: [Any] = [iso8601Formatter, ymdhmFormatter, mdyhmFormatter, dmyhmFormatter]
            
            // Parse the total amount
            let total = (Double(json.total.replacingOccurrences(of: ",", with: "")) ?? 0.0)
            
            // Convert item prices from strings to doubles
            let items = json.items.map { item in
                let price = Double(item.price.replacingOccurrences(of: ",", with: "")) ?? 0.0
                return "\(item.name): \(json.currency ?? "¥")\(String(format: "%.2f", price))"
            }
            
            // Try each formatter
            for formatter in formatters {
                if let date = (formatter as? ISO8601DateFormatter)?.date(from: json.date) ?? 
                             (formatter as? DateFormatter)?.date(from: json.date) {
                    
                    return Receipt(
                        id: UUID().uuidString,
                        date: date,
                        total: total,
                        items: items,
                        storeName: json.storeName ?? "Unknown Shop",
                        currency: json.currency ?? "¥" // Default to yen for Japanese receipts
                    )
                }
            }
            
            // If no formatter worked, throw the error
            throw NSError(domain: "FirebaseService", code: 6,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid date format: \(json.date)"])
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
        
        let receiptData: [String: Any] = [
            "date": receipt.date,
            "total": receipt.total,
            "items": receipt.items,
            "storeName": receipt.storeName,
            "currency": receipt.currency,
            "userId": userId,
            "imageURL": receipt.imageURL ?? ""
        ]
        
        try await db.collection("receipts").document(receipt.id).setData(receiptData)
    }
    
    func fetchReceipts(from startDate: Date = Date.distantPast, 
                       to endDate: Date = Date()) async throws -> [Receipt] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirebaseService", code: 2,
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Convert dates to Timestamp for Firestore query
        let startTimestamp = Timestamp(date: startDate)
        let endTimestamp = Timestamp(date: endDate)
        
        let snapshot = try await db.collection("receipts")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: startTimestamp)
            .whereField("date", isLessThanOrEqualTo: endTimestamp)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            guard let timestamp = data["date"] as? Timestamp,
                  let total = data["total"] as? Double,
                  let items = data["items"] as? [String],
                  let storeName = data["storeName"] as? String,
                  let currency = data["currency"] as? String else {
                return nil
            }
            
            let imageURL = data["imageURL"] as? String
            
            return Receipt(
                id: document.documentID,
                date: timestamp.dateValue(),
                total: total,
                items: items,
                storeName: storeName,
                currency: currency,
                imageURL: imageURL
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
            storeName: "Processing...",
            currency: "$"
        )
    }
    
    func deleteReceipt(_ receiptId: String) async throws {
        guard (Auth.auth().currentUser?.uid) != nil else {
            throw NSError(domain: "FirebaseService", code: 2, 
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await db.collection("receipts").document(receiptId).delete()
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
