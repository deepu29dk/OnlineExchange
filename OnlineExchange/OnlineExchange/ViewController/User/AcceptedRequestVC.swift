//
//  AcceptedRequestVC.swift
//  SmartInventory
//
//  Created by Macbook-Pro on 18/09/24.
//

import UIKit

class AcceptedRequestVC: BaseViewController,UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var productsRequest: [ProductModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.fetchProductData()
    }

    func fetchProductData() {
        FireStoreManager.shared.getAllRequestProductRecord(forUserId: UserDefaultsManager.shared.getDocumentId(), collectionStatus: "BidAcceptedByOwnerOfUser") { [weak self] fetchedProducts, error in
              if let error = error {
                  print("Error fetching products: \(error.localizedDescription)")
              } else if let fetchedProducts = fetchedProducts {
                  self?.productsRequest = fetchedProducts
                  self?.tableView.reloadData()
              }
          }
      }
    
//    func calculatePricePerProduct(){
//        let quantityString = productRecord?.quantity ?? ""
//        let pricePerProductString = productRecord?.price ?? ""
//
//        let cleanedPriceString = pricePerProductString.replacingOccurrences(of: "$", with: "")
//
//        if let quantity = Int(quantityString), let pricePerProduct = Double(cleanedPriceString) {
//            let totalPrice = Double(quantity) * pricePerProduct
//            self.totalPrice = String(format: "%.2f", totalPrice)
//
//            print("Total price: $\(self.totalPrice)")
//
//            self.payBtn.setTitle("Pay $\(self.totalPrice)", for: .normal)
//        } else {
//            print("Invalid input")
//        }
//    }
//
//    @IBAction func onMakePayment(_ sender: Any) {
//        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PaymentScreen") as! PaymentScreen
//        vc.payamount = self.totalPrice
//        vc.requestId = self.productRecord?.requestId ?? ""
//        vc.managerId = self.productRecord?.managerid ?? ""
//        self.navigationController?.pushViewController(vc, animated: true)
//    }
}


extension AcceptedRequestVC {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.productsRequest.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:  String(describing: TableViewCell.self), for: indexPath) as! TableViewCell
       
        let data = self.productsRequest[indexPath.row]
        cell.productName.text = "Product Name: \(data.productname)"
        cell.quantity.text = "Quantity: \(data.quantity)"
        cell.price.text = "Bid Price: \(data.bidPrice)"
        cell.productDetail.text = "Detail: \(data.productDetail)"
        
        let imageUrl = data.productImageUrl

        cell.productImage.sd_setImage(with: URL(string: imageUrl), placeholderImage: UIImage(named: "logo"))
        
        cell.acceptBtn.tag = indexPath.row
        cell.acceptBtn.addTarget(self, action: #selector(self.acceptAppointmentStatus(_:)), for: .touchUpInside)

        if data.paymentStatus != "Done" {
            cell.payBtn.isHidden = false
            cell.payBtn.tag = indexPath.row
            cell.payBtn.addTarget(self, action: #selector(self.makePayment(_:)), for: .touchUpInside)
        } else {
            cell.payBtn.isHidden = true
        }
        
        return cell
    }
    
    @objc func acceptAppointmentStatus(_ sender: UIButton) {
        
        let data = productsRequest[sender.tag]
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ChatVC") as! ChatVC
        vc.chatID = getChatID(email1: data.adminEmail, email2: data.userEmail)
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    @objc func makePayment(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PaymentScreen") as! PaymentScreen
        vc.product = productsRequest[sender.tag]
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 155
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
      
    }
}
