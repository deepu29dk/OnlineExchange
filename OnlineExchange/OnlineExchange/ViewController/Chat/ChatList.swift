 
import UIKit

class ChatList: UITableViewCell {

    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var unreadCountLabel: UILabel!
    @IBOutlet weak var countView: UIView!

    override func awakeFromNib() {
        container.dropShadow(shadowRadius: 10)
    }
    
    func setData(message: MessageModel) {
        self.email.text  = "Email - \(message.sender)"
        self.time.text  = message.dateSent.getTimeOnly()
        self.message.text  = message.text
        
        countView.layer.cornerRadius = 15.0
        countView.clipsToBounds = true
    }
    
    func updateUnreadCount(_ count: Int) {
        countView.isHidden = (count == 0)
        unreadCountLabel.text = count > 0 ? "\(count)" : nil
    }
}


//class chaty {
//    @IBOutlet weak var chatContainer: UIView!
//    @IBOutlet weak var textView: TextViewWithPlaceholder!
//    @IBOutlet weak var tableView: UITableView!
//    @IBOutlet weak var textViewBottomConstraint: NSLayoutConstraint!
//    @IBOutlet weak var btnOptions: UIButton!
//    @IBOutlet weak var addImages: UIButton!
//    @IBOutlet weak var btnViewProfile: UIButton!
//    @IBOutlet weak var sendMessageView: UIView!
//
//    let id = getEmail()
//    var chatID = ""
//    var messages = [MessageModel]()
//    var senderId = getEmail()
//    var senderName = UserDefaultsManager.shared.getFullname()
//    var recipientID = UserDefaultsManager.shared.getDocumentId()
//    var unreadCountListener: ListenerRegistration?
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.setTableView()
//        self.getMessages()
//        self.observeUnreadCount()
//
//        let userType = UserDefaultsManager.shared.getUserType()
//        self.chatContainer.isHidden = (userType == UserType.admin.rawValue)
//    }
//
//    func shortMessages() {
//        messages = messages.sorted { $0.getDate().compare($1.getDate()) == .orderedAscending }
//    }
//
//    func getMessages() {
//        FireStoreManager.shared.getLatestMessages(chatID: chatID) { (documents, error) in
//            if let error = error {
//                print("Error retrieving messages: \(error)")
//            } else if let documents = documents {
//                self.messages = documents.map { MessageModel(data: $0.data()) }
//                self.shortMessages()
//                self.reloadData()
//                self.resetUnreadCount()  // Mark messages as read when viewing
//            }
//        }
//    }
//
//
//    @IBAction func onSend(_ sender: Any) {
//        guard let text = self.textView.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
//            showAlerOnTop(message: "Please enter Text")
//            return
//        }
//
//        self.textView.text = ""
//        self.sendTextMessage(text: text)
//    }
//
//    func sendTextMessage(text: String) {
//        self.view.endEditing(true)
//        FireStoreManager.shared.saveChat(
//            userEmail: getEmail().lowercased(),
//            text: text,
//            time: getTime(),
//            chatID: chatID
//        )
//        incrementUnreadCount(for: recipientID)  // Update unread count for the recipient
//    }
//
//    func getTime() -> Double {
//        return Double(Date().millisecondsSince1970)
//    }
//
//    func reloadData() {
//        self.tableView.reloadData()
//        self.tableView.scroll(to: .bottom, animated: true)
//        self.updateTableContentInset()
//    }
//
//    
//    //Add this function below
//    func updateTableContentInset() {
//        let numRows = self.tableView.numberOfRows(inSection: 0)
//        var contentInsetTop = self.tableView.bounds.size.height
//        for i in 0..<numRows {
//            let rowRect = self.tableView.rectForRow(at: IndexPath(item: i, section: 0))
//            contentInsetTop -= rowRect.size.height
//            if contentInsetTop <= 0 {
//                contentInsetTop = 0
//                break
//            }
//        }
// 
//    }
//}
