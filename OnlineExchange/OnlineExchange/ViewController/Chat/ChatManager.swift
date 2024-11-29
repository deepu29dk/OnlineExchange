import FirebaseFirestore

class ChatManager {
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    // Replace this with the method you use to retrieve the current user's ID from Firestore
    private var currentUserID: String {
        return UserDefaultsManager.shared.getDocumentId() // Update this to retrieve the current user ID from your Firestore data structure
    }

    // Set up real-time listener for unread messages
    func observeUnreadMessagesCount(for chatID: String, completion: @escaping (Int) -> Void) {
        listener?.remove() // Remove previous listener if any
        
        listener = db.collection("Chat").document(chatID).collection("Messages")
            .whereField("isRead", isEqualTo: false)
            .whereField("recipientID", isEqualTo: currentUserID) // Messages intended for current user
            .addSnapshotListener { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching unread messages: \(error)")
                    return
                }
                
                // Unread messages count
                let unreadCount = querySnapshot?.documents.count ?? 0
                completion(unreadCount)
            }
    }
    
    // Mark messages as read
    func markMessagesAsRead(for chatID: String) {
        db.collection("Chat").document(chatID).collection("Messages")
            .whereField("isRead", isEqualTo: false)
            .whereField("recipientID", isEqualTo: currentUserID)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error marking messages as read: \(error)")
                    return
                }
                
                querySnapshot?.documents.forEach { document in
                    document.reference.updateData(["isRead": true])
                }
            }
    }
    
    deinit {
        listener?.remove()
    }
}
