//
//  PaymentListVC.swift
//  SmartInventory
//
//  Created by Macbook-Pro on 27/09/24.
//

import UIKit

class PaymentListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var products: [ProductModel] = []
    var isManager = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        let id = UserDefaultsManager.shared.getDocumentId()
        FireStoreManager.shared.getPaymentHistoryList { list, error in
            self.products = (list ?? []).filter({ $0.userId == id || $0.adminId == id })
            self.tableView.reloadData()
        }
    }
    
    @IBAction func onBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

}


extension PaymentListVC {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:  String(describing: TableViewCell.self), for: indexPath) as! TableViewCell
        let data = self.products[indexPath.row]
        let price = (Int(data.bidPrice) ?? 0)
        let qunatity = (Int(data.quantity) ?? 0)

        cell.productName.text = "Product Name: \(data.productname)"
        cell.quantity.text = "Quantity: \(data.quantity)"
        cell.price.text = "Amount: " + "$\(Int(price * qunatity))"
        let isuser = UserDefaultsManager.shared.getDocumentId() == data.userId
        cell.productDetail.text = isuser ? ("Seller Id : " + data.adminId) : ("User Id : " + data.userId)
        cell.userid.text = isuser ? "Payment Success" : "Payment Received"

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
