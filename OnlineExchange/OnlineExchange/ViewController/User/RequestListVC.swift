//
//  RequestListVC.swift
//  SmartInventory
//
//  Created by Macbook-Pro on 16/09/24.
//

import UIKit

class RequestListVC: BaseViewController {
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var containerView: UIView!
    
    // MARK: - Child View Controllers
    var acceptedViewController: AcceptedRequestVC!
    var rejectedViewController: RejectedRequestVC!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        acceptedViewController = storyboard.instantiateViewController(withIdentifier: "AcceptedRequestVC") as? AcceptedRequestVC
        rejectedViewController = storyboard.instantiateViewController(withIdentifier: "RejectedRequestVC") as? RejectedRequestVC
        
        displayCurrentViewController(selectedSegmentIndex: segmentedControl.selectedSegmentIndex)
    }
    
    // MARK: - Segment Control Action
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        displayCurrentViewController(selectedSegmentIndex: sender.selectedSegmentIndex)
    }
    
    // MARK: - Switch between child view controllers
    func displayCurrentViewController(selectedSegmentIndex: Int) {
        // Remove existing child view controller
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        // Add the new child view controller based on selected segment
        switch selectedSegmentIndex {
        case 0:
            embedChildViewController(acceptedViewController)
        case 1:
            embedChildViewController(rejectedViewController)
        default:
            break
        }
    }
    
    // MARK: - Add child view controller method
    func embedChildViewController(_ viewController: UIViewController) {
        addChild(viewController)

        viewController.view.frame = containerView.bounds
        
        containerView.addSubview(viewController.view)
        
        viewController.didMove(toParent: self)
    }


}
