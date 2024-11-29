

import UIKit

class SignUpVC: BaseViewController {
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var confirmPassword: UITextField!
    @IBOutlet weak var fullname: UITextField!

    var userType = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onSignUp(_ sender: Any) {
        if validate() {
            let signupData = SignupModel(fullname: self.fullname.text?.capitalized ?? "", email: self.email.text?.lowercased() ?? "", password: (self.password.text ?? "").encryptStr, userType: userType)
            FireStoreManager.shared.signUp(email: self.email.text?.lowercased() ?? "", signupData: signupData)
        }
    }

    @IBAction func onLogin(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func validate() ->Bool {
        
        if(self.email.text!.isEmpty) {
             showAlerOnTop(message: "Please enter email.")
            return false
        }
        
        if !email.text!.emailIsCorrect() {
            showAlerOnTop(message: "Please enter valid email id")
            return false
        }
        
        if(self.fullname.text!.isEmpty) {
             showAlerOnTop(message: "Please enter full name.")
            return false
        }
        
        if(self.password.text!.isEmpty) {
             showAlerOnTop(message: "Please enter password.")
            return false
        }
        
        if(self.confirmPassword.text!.isEmpty) {
             showAlerOnTop(message: "Please enter confirm password.")
            return false
        }
        
           if(self.password.text! != self.confirmPassword.text!) {
             showAlerOnTop(message: "Password doesn't match")
            return false
        }
        
        if(self.password.text!.count < 5 || self.password.text!.count > 10 ) {
            
             showAlerOnTop(message: "Password  length shoud be 5 to 10")
            return false
        }
        
        
        return true
    }

    
    @IBAction func onShowHidePassword(_ sender: UIButton) {
        
        if(sender.tag == 1) {
            let buttonImageName = password.isSecureTextEntry ? "eye" : "eye.slash"
            if let buttonImage = UIImage(systemName: buttonImageName) {
                sender.setImage(buttonImage, for: .normal)
            }
            self.password.isSecureTextEntry.toggle()
        }
        
        if(sender.tag == 2) {
            let buttonImageName = confirmPassword.isSecureTextEntry ? "eye" : "eye.slash"
            if let buttonImage = UIImage(systemName: buttonImageName) {
                sender.setImage(buttonImage, for: .normal)
            }
            self.confirmPassword.isSecureTextEntry.toggle()
        }
    }
}



