import UIKit
import FirebaseFirestore

class ChatListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var messages = [MessageModel]()
    var unreadCounts = [String: Int]() // Dictionary to hold unread counts for each chatID
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings
        
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.register(UINib(nibName: "ChatList", bundle: nil), forCellReuseIdentifier: "ChatList")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let userType = UserDefaultsManager.shared.getUserType()
        if userType == UserType.admin.rawValue {
            getmessageForAdmin()
        } else {
            getMessages()
        }
    }
    
    
    @IBAction func actionNavigationBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    
    @IBAction func actionDismiss(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    func shortMessages() {
        messages = messages.sorted(by: {
            $0.getDate().compare($1.getDate()) == .orderedDescending
        })
    }
    
    func getMessages() {
        FireStoreManager.shared.getChatList(userEmail: UserDefaultsManager.shared.getEmail()) { (documents, error) in
            if let error = error {
                print("Error retrieving messages: \(error)")
            } else if let documents = documents {
                var messages = [MessageModel]()
                for document in documents {
                    let data = document.data()
                    let message = MessageModel(data: data)
                    messages.append(message)
                    
                    // Fetch unread count for each chatID
                    self.fetchUnreadCount(chatID: message.chatId)
                }
                self.messages = messages
                self.shortMessages()
                self.tableView.reloadData()
            }
        }
    }
    
    
    func getmessageForAdmin() {
        FireStoreManager.shared.getChatList { (documents, error) in
            if let error = error {
                print("Error retrieving messages: \(error)")
            } else if let documents = documents {
                var messages = [MessageModel]()
                for document in documents {
                    let data = document.data()
                    let message = MessageModel(data: data)
                    messages.append(message)
                    
                    // Fetch unread count for each chatID
                    self.fetchUnreadCount(chatID: message.chatId)
                }
                self.messages = messages
                self.shortMessages()
                self.tableView.reloadData()
            }
        }
    }
    
//    func fetchUnreadCount(chatID: String) {
//        let chatRef = Firestore.firestore().collection("Chat").document(chatID)
//        chatRef.getDocument { (document, error) in
//            if let document = document, document.exists {
//                if let unreadCountData = document.data()?["unreadCount"] as? [String: Any] {
//                    print("Unread count data:", unreadCountData) // Print full unread count data
//                    
//                    let userEmail = UserDefaultsManager.shared.getEmail()
//                    let emailParts = userEmail.components(separatedBy: "@")
//                    
//                    if emailParts.count == 2 {
//                        let emailKey = emailParts[0] + "@" + emailParts[1].components(separatedBy: ".").first!
//                        print("Looking for unread count with key:", emailKey)
//                        
//                        if let userCounts = unreadCountData[emailKey] as? [String: Any],
//                           let userUnreadCount = userCounts["com"] as? Int {
//                            self.unreadCounts[chatID] = userUnreadCount
//                            print("Unread count for \(userEmail):", userUnreadCount)
//                            
//                            self.tableView.reloadData()
//
//                        } else {
//                            print("No data found for emailKey:", emailKey)
//                            self.unreadCounts[chatID] = 0
//                        }
//                    } else {
//                        print("Email format issue or parsing error for userEmail:", userEmail)
//                        self.unreadCounts[chatID] = 0
//                    }
//                } else {
//                    print("Unread count data not found or incorrect format")
//                    self.unreadCounts[chatID] = 0 // No unread count, set to 0
//                }
//                
//                // Reload the specific row in the tableView
//                if let row = self.messages.firstIndex(where: { $0.chatId == chatID }) {
//                    let indexPath = IndexPath(row: row, section: 0)
//                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
//                }
//            } else {
//                print("Error fetching unread count: \(error?.localizedDescription ?? "Unknown error")")
//            }
//        }
//    }
    
    
    func fetchUnreadCount(chatID: String) {
        let chatRef = Firestore.firestore().collection("Chat").document(chatID)
        chatRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot, document.exists else {
                print("Error listening to unread count changes:", error?.localizedDescription ?? "Unknown error")
                return
            }
            
            if let unreadCountData = document.data()?["unreadCount"] as? [String: Any] {
                let userEmail = UserDefaultsManager.shared.getEmail()
                let emailParts = userEmail.components(separatedBy: "@")
                
                if emailParts.count == 2 {
                    let emailKey = emailParts[0] + "@" + emailParts[1].components(separatedBy: ".").first!
                    
                    if let userCounts = unreadCountData[emailKey] as? [String: Any],
                       let userUnreadCount = userCounts["com"] as? Int {
                        self.unreadCounts[chatID] = userUnreadCount
                        print("Updated unread count for \(userEmail):", userUnreadCount)
                        
                        self.tableView.reloadData()
                    } else {
                        self.unreadCounts[chatID] = 0
                    }
                } else {
                    print("Email format issue or parsing error for userEmail:", userEmail)
                    self.unreadCounts[chatID] = 0
                }
            } else {
                self.unreadCounts[chatID] = 0
            }
        }
    }

    
    
    
    func reloadCellForChatID(_ chatID: String) {
        if let row = messages.firstIndex(where: { $0.chatId == chatID }) {
            let indexPath = IndexPath(row: row, section: 0)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatList", for: indexPath) as! ChatList
        let message = messages[indexPath.row]
        
        // Set the data for the cell, including unread count
        cell.setData(message: message)
        let unreadCount = unreadCounts[message.chatId] ?? 0
        cell.updateUnreadCount(unreadCount)
        
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        let vc = storyboard?.instantiateViewController(withIdentifier: "ChatVC") as! ChatVC
        vc.chatID = message.chatId
        navigationController?.pushViewController(vc, animated: true)
    }
}
