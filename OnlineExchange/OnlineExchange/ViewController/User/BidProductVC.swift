

import UIKit
import SDWebImage

class BidProductVC: BaseViewController, UITextFieldDelegate {
    
    @IBOutlet weak var detailTxt: UITextView!
    @IBOutlet weak var productNameTxt: UITextField!
    @IBOutlet weak var priceTxt: UITextField!
    @IBOutlet weak var quantityTxt: UITextField!
    @IBOutlet weak var productimage: UIImageView!
    @IBOutlet weak var bidpriceTxt: UITextField!
    @IBOutlet weak var highestbidpriceTxt: UITextField!

    var productData: ProductModel?
    var bidPrice = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showProductData()
        
        bidpriceTxt.delegate = self
        
    }
    
    
    func showProductData(){
        self.productNameTxt.text = productData?.productname
        self.priceTxt.text = productData?.price
        self.quantityTxt.text = productData?.quantity
        self.detailTxt.text = productData?.productDetail
        self.highestbidpriceTxt.text = productData?.bidPrice

        let imageUrl = productData?.productImageUrl ?? ""
        
        self.productimage.sd_setImage(with: URL(string: imageUrl), placeholderImage: UIImage(named: "logo"))
        
        bidPrice = Int(productData?.bidPrice ?? "0") ?? 0
    }
    
    @IBAction func btnAddBid(_ sender: UIButton) {
        guard let text = bidpriceTxt.text, let enteredPrice = Int(text) else {
            showAlerOnTop(message: "Please enter bid amount.")
            return
        }
        
        if enteredPrice > bidPrice {
            print("Valid price entered: \(enteredPrice). Proceeding...")
            
            if(bidpriceTxt.text!.isEmpty) {
                showAlerOnTop(message: "Please enter bid price")
                return
                
            } else {
                let data = ProductModel(productname: self.productData?.productname ?? "", adminId: self.productData?.adminId ?? "", price: self.productData?.price ?? "", quantity: self.quantityTxt.text ?? "", productImageUrl: self.productData?.productImageUrl ?? "", userId: UserDefaultsManager.shared.getDocumentId(), availableQuantity: self.productData?.availableQuantity ?? "", productDetail: self.productData?.productDetail ?? "",adminEmail: self.productData?.adminEmail ?? "",userEmail: UserDefaultsManager.shared.getEmail(), product_id: self.productData?.product_id ?? "", bidPrice: self.bidpriceTxt.text ?? "", added_time: self.productData?.added_time ?? 0)
                
                let productDocumentId = "\(self.productData?.productname ?? "")-\(self.productData?.price ?? "")-\(self.quantityTxt.text ?? "")-\(UserDefaultsManager.shared.getDocumentId())"
                
                FireStoreManager.shared.processProductRequestAndUpdateBid(documentID: UserDefaultsManager.shared.getDocumentId(), adminId: self.productData?.adminId ?? "", product: data, newBidPrice: self.bidpriceTxt.text ?? "", bidproduct_id: self.productData?.product_id ?? "", productDocumentId: productDocumentId) { success in
                    if success {
                        showAlerOnTop(message: "Place bid successfully. Request send to admin")
                        self.navigationController?.popToRootViewController(animated: true)
                    } else {
                        showAlerOnTop(message: "You already placed bid for this item.")
                    }
                }
            }
        } else {
            
            showAlerOnTop(message: "Price must be greater than \(self.highestbidpriceTxt.text ?? "") rupees.")
        }
    }
}
