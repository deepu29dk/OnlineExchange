
import UIKit
import FirebaseStorage

class AddProductVC: BaseViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate  {
    @IBOutlet weak var productDetailTxt: UITextView!
    @IBOutlet weak var productNameTxt: UITextField!
    @IBOutlet weak var priceTxt: UITextField!
    @IBOutlet weak var quantityTxt: UITextField!
    @IBOutlet weak var productImage: UIImageView!
    @IBOutlet weak var addFileName: UILabel!
    let imagePicker = UIImagePickerController()
    var activityIndicator: UIActivityIndicatorView!
    var selectedimage = UIImage()

    override func viewDidLoad() {
        super.viewDidLoad()
        productDetailTxt.delegate = self
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)

    }

    
    @IBAction func onSubmit(_ sender: Any) {
        if validate(){
            self.activityIndicator.startAnimating()
            self.view.isUserInteractionEnabled = false
            self.uploadImageToFirebase(image: selectedimage, imageName: self.addFileName.text ?? "")
        }
    }
    

    func validate() ->Bool {
        
        if(self.productNameTxt.text!.isEmpty) {
             showAlerOnTop(message: "Please enter Product name.")
            return false
        }
        if(self.priceTxt.text!.isEmpty) {
             showAlerOnTop(message: "Please enter price per product")
            return false
        } 
        if(self.quantityTxt.text!.isEmpty) {
            showAlerOnTop(message: "Please enter Quantity")
           return false
       } 
        if !isValidInteger(self.quantityTxt.text ?? ""){
            showAlerOnTop(message: "Please enter valid Quantity")
           return false
        }
        
        if(self.addFileName.text!.isEmpty) {
            showAlerOnTop(message: "Please select product image")
            return false
        }
        
        if(self.productDetailTxt.text!.isEmpty) {
            showAlerOnTop(message: "Please enter product detail")
            return false
        }
        
        if(self.productDetailTxt.text == "Product Detail") {
            showAlerOnTop(message: "Please enter product detail")
            return false
        }
        
        return true
    }
    
    func isValidInteger(_ input: String) -> Bool {
        return Int(input) != nil
    }

}

extension AddProductVC{
    @IBAction func uploadFileAction(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            if let imageURL = info[UIImagePickerController.InfoKey.imageURL] as? URL {
                let imageName = imageURL.lastPathComponent
                print("Image Name: \(imageName)")
                self.productImage.image = selectedImage
                self.selectedimage = selectedImage
                self.addFileName.text = imageName
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    
}


extension AddProductVC{
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Product Detail"{
                textView.text = ""
                textView.textColor = UIColor.black
        }
    }

       func textViewDidEndEditing(_ textView: UITextView) {
           if textView.text.isEmpty {
               textView.text = "Product Detail"
               textView.textColor = UIColor.lightGray
           }
       }
}


extension AddProductVC {
    func uploadImageToFirebase(image: UIImage, imageName: String) {
        let storage = Storage.storage()
        let email = UserDefaultsManager.shared.getEmail()
        let imageRef = storage.reference().child("Documents/\(email)/\(imageName)")
        
        if let imageData = image.jpegData(compressionQuality: 0.7) {
            imageRef.putData(imageData, metadata: nil) { (metadata, error) in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                } else {
                    print("Image uploaded successfully")
                    imageRef.downloadURL { (url: URL?, error: Error?) in
                        if let error = error {
                            print("Error fetching download URL: \(error.localizedDescription)")
                        } else if let downloadURL = url {
                            let stringValue = downloadURL.absoluteString
                            self.uploadRequestToFirestore(fileUrl: stringValue)
                        }
                    }
                }
            }
        }
    }
    
    func uploadRequestToFirestore(fileUrl: String){
        let requestModel = ProductModel(productname: self.productNameTxt.text ?? "", adminId: UserDefaultsManager.shared.getDocumentId(), price: self.priceTxt.text ?? "", quantity: self.quantityTxt.text ?? "", productImageUrl: fileUrl, userId: "", availableQuantity: self.quantityTxt.text ?? "", productDetail: self.productDetailTxt.text ?? "",adminEmail: UserDefaultsManager.shared.getEmail(),userEmail: "", product_id: "", bidPrice: self.priceTxt.text ?? "", added_time: Int(Date().timeIntervalSince1970))
        
        FireStoreManager.shared.addProductDetail(documentID: UserDefaultsManager.shared.getDocumentId(), product: requestModel) { success in
            if success {
                self.activityIndicator.startAnimating()
                self.activityIndicator.removeFromSuperview()
                showAlerOnTop(message: "Product added successfully")
                self.navigationController?.popViewController(animated: true)
            } else {
                self.activityIndicator.startAnimating()
                self.activityIndicator.removeFromSuperview()
                showAlerOnTop(message: "Facing some issue")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
