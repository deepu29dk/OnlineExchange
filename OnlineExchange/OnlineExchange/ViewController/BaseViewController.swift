
import UIKit

class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func viewWillAppear() {
        super.viewWillAppear(true)
    }
    
    @IBAction func actionNavigationBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    
    @IBAction func actionDismiss(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
}
