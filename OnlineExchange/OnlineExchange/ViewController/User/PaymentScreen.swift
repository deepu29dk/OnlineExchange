 
import UIKit

class PaymentScreen: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,UITextFieldDelegate {
    
    var images = ["discover", "echeck", "master card", "pay pal"]
    
    @IBOutlet weak var selectedCard: UILabel!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var number: UITextField!
    @IBOutlet weak var cvv: UITextField!
    @IBOutlet weak var billingAddress: UITextField!
   
    @IBOutlet weak var amount: UILabel!
    var selectedCardText = ""
    var product : ProductModel?

    override func viewDidLoad() {
        super.viewDidLoad()
            
        let price = (Int(product?.bidPrice ?? "0") ?? 0)
        let qunatity = (Int(product?.quantity ?? "0") ?? 0)
        amount.text = "$\(Int(price * qunatity))"
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.number.delegate = self
        self.cvv.delegate = self
        self.name.delegate = self
        let layout = UICollectionViewFlowLayout()
               layout.scrollDirection = .horizontal
               layout.minimumInteritemSpacing = 10
               layout.minimumLineSpacing = 10
               layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
               collectionView.setCollectionViewLayout(layout, animated: true)
        
        // Limit the CVV text field to 3 characters
                self.cvv.delegate = self
                self.cvv.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

                // Limit the account number text field to 16 characters
                self.number.delegate = self
                self.number.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    @IBAction func onPay(_ sender: Any) {
        let name = self.name.text!
        let number = self.number.text!
        let cvv = self.cvv.text!

        if name.isEmpty || number.isEmpty || cvv.isEmpty {
            showAlert(message: "Please enter all the details")
        } else if self.billingAddress.text!.isEmpty {
            showAlert(message: "Please enter billing address")
        } else if selectedCardText.isEmpty {
            showAlert(message: "Please select card")
        } else if number.count != 16 { // Check if the account number is not exactly 16 digits
            showAlert(message: "Account number must be 16 digits")
        } else if cvv.count != 4 { // Check if the CVV is not exactly 4 digits
            showAlert(message: "CVV must be 4 digits")
        } else {
            
            FireStoreManager.shared.addPaymentHistory(product: self.product!) { result in
                let alert = UIAlertController(title: "Message", message: "Payment Success 😊", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    
                    let vc = self.storyboard?.instantiateViewController(withIdentifier:  "FeedbackVC" ) as! FeedbackVC
                            
                    self.navigationController?.pushViewController(vc, animated: true)

                }))
                self.present(alert, animated: true, completion: nil)
            }
            
//            FireStoreManager.shared.updatePaymentStatus(forUserId: UserDefaultsManager.shared.getDocumentId(), requestId: self.requestId, newPaymentStatus: "Success") { success, error in
//                if success {
//                    showOkAlertAnyWhereWithCallBack(message: "Payment Success 😊") {
//                        self.navigationController?.popToRootViewController(animated: true)
//                    }
//                    FireStoreManager.shared.updatePaymentStatusInManagerPaymentList(forManagerId: self.managerId, requestId: self.requestId, newPaymentStatus: "Success") { isSuccess, error in
//                    }
//                }
//            }
        }
    }


    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.name {
            let allowedCharacterSet = CharacterSet.letters
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacterSet.isSuperset(of: characterSet)
        } else if textField == self.number || textField == self.cvv {
            let allowedCharacterSet = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacterSet.isSuperset(of: characterSet)
        }
        return true
    }
    @IBAction func onPrevious(_ sender: Any) {
        // Calculate the index of the previous item
        if let firstVisibleIndexPath = collectionView.indexPathsForVisibleItems.first,
           firstVisibleIndexPath.item > 0 {
            let previousIndexPath = IndexPath(item: firstVisibleIndexPath.item - 1, section: firstVisibleIndexPath.section)
            
            // Scroll to the previous item
            collectionView.scrollToItem(at: previousIndexPath, at: .centeredHorizontally, animated: true)
        }
    }

    @IBAction func onNext(_ sender: Any) {
        // Calculate the index of the next item
        if let lastVisibleIndexPath = collectionView.indexPathsForVisibleItems.last,
           lastVisibleIndexPath.item < images.count - 1 {
            let nextIndexPath = IndexPath(item: lastVisibleIndexPath.item + 1, section: lastVisibleIndexPath.section)
            
            // Scroll to the next item
            collectionView.scrollToItem(at: nextIndexPath, at: .centeredHorizontally, animated: true)
        }
    }

    @IBAction func onBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    
    func showAlert(message:String) {
        let alert = UIAlertController(title: "Message", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCell", for: indexPath) as! CardCell
        cell.cardImage.image = UIImage(named: images[indexPath.row])
        cell.cardImage.contentMode = .scaleAspectFit
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedCardText = images[indexPath.row]
        self.selectedCard.text = images[indexPath.row]
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let cellWidth = collectionView.bounds.width / 1 - 15
            return CGSize(width: cellWidth, height: cellWidth)
        }
}

class CardCell: UICollectionViewCell {

    @IBOutlet weak var cardImage: UIImageView!
    

}

extension PaymentScreen {
    
    // Add a common method to limit text field length
       @objc func textFieldDidChange(_ textField: UITextField) {
           if textField == self.cvv {
               if let text = textField.text, text.count > 4 {
                   textField.text = String(text.prefix(4))
               }
           } else if textField == self.number {
               if let text = textField.text, text.count > 16 {
                   textField.text = String(text.prefix(16))
               }
           }
       }
}
