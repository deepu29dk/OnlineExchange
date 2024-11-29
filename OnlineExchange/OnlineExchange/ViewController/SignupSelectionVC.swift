//

import UIKit
import LocalAuthentication

class SignupSelectionVC: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func onAdmin(_ sender: Any)
    {
        let vc = self.storyboard?.instantiateViewController(withIdentifier:  "SignUpVC" ) as! SignUpVC
        vc.userType = "Admin"
        self.navigationController?.pushViewController(vc, animated: true)
        
        
    }
    
    @IBAction func onUser(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier:  "SignUpVC" ) as! SignUpVC
        vc.userType = "User"
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

