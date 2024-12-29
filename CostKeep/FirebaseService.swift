import FirebaseStorage
import FirebaseFirestore
import FirebaseVertexAI
import UIKit
import FirebaseAuth

class FirebaseService {
    static let shared = FirebaseService()
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    func uploadReceiptImage(_ image: UIImage) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirebaseService", code: 2, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            throw NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let filename = "\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child("receipts/\(userId)/\(filename)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    func processReceiptImage(_ image: UIImage) async throws -> Receipt {
        // Upload image to Firebase Storage
        let imageUrl = try await uploadReceiptImage(image)
        
        // For now, we'll just create a basic receipt
        // You'll need to implement the actual Vertex AI integration once you have
        // the correct API access and documentation
        return Receipt(
            date: Date(),
            total: 0.0,
            items: []
        )
    }
    
    func saveReceipt(_ receipt: Receipt) async throws {
        try await db.collection("receipts").document(receipt.id.uuidString).setData([
            "date": receipt.date,
            "total": receipt.total,
            "items": receipt.items
        ])
    }
}