

import UIKit

class BidRequestVC: BaseViewController,UITableViewDelegate, UITableViewDataSource {
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
        FireStoreManager.shared.getBidRequests(forUserId: UserDefaultsManager.shared.getDocumentId()) { [weak self] fetchedProducts, error in
              if let error = error {
                  print("Error fetching products: \(error.localizedDescription)")
              } else if let fetchedProducts = fetchedProducts {
                  self?.productsRequest = fetchedProducts
                  self?.tableView.reloadData()
              }
          }
      }
    
}


extension BidRequestVC {
    
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
        cell.rejectBtn.tag = indexPath.row
        cell.acceptBtn.addTarget(self, action: #selector(self.acceptAppointmentStatus(_:)), for: .touchUpInside)
        cell.rejectBtn.addTarget(self, action: #selector(self.rejectAppointmentStatus(_:)), for: .touchUpInside)

        return cell
    }
    
    @objc func acceptAppointmentStatus(_ sender: UIButton) {
        let request = self.productsRequest[sender.tag]
        self.updateAcceptRequest(status: "Accept", requestData: request)
    }
    
    @objc func rejectAppointmentStatus(_ sender: UIButton) {
        let request = self.productsRequest[sender.tag]
        self.rejectUpdateRequest(status: "Reject", requestData: request)
    }
    
    
    func updateAcceptRequest(status: String, requestData: ProductModel!){
        FireStoreManager.shared.acceptProductRequest(request: requestData) { success in
                        if success {
                            showAlerOnTop(message: "Product Accepted!!")
                            self.navigationController?.popViewController(animated: true)
                            
                            FireStoreManager.shared.addToAcceptedOrderList(product: requestData) { result in
                                print(result)
                            }
                        }
                    }
    }
    
    func rejectUpdateRequest(status: String, requestData: ProductModel!){
        FireStoreManager.shared.rejectProductRequest(request: requestData) { success in
                        if success {
                            showAlerOnTop(message: "Product Rejected!!")
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
