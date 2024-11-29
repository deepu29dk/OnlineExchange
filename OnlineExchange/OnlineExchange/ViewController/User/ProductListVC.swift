
import UIKit
import SDWebImage

enum userValue {
    case manager
}

var colorThemeGreen = UIColor(red: 94/250, green: 193/250, blue: 129/250, alpha: 1.0)

class ProductListVC: BaseViewController ,UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    var products: [ProductModel] = []
    var filteredProducts: [ProductModel] = []
    var isSearching = false
    var arrWishlistProducts: [ProductModel] = []
    var arrSoldOutProducts: [ProductModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchBar()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        FireStoreManager.shared.getAcceptedProductList { list, error in
            self.arrSoldOutProducts = list ?? []
        }
        
        FireStoreManager.shared.getProductWishList(userID: UserDefaultsManager.shared.getDocumentId(), searchStr: "") { list, error in
            if let productsArray = list {
                self.arrWishlistProducts = productsArray
                productsArray.forEach { product in
                    print("getProductWishList - ", product.productname)
                }
            }
        }
        
        FireStoreManager.shared.getAdminProducts { [weak self] productsArray, error in
            guard let self = self else { return }
            if let productsArray = productsArray {
                self.products = productsArray.sorted { $0.added_time > $1.added_time }
                self.tableView.reloadData()
            }
        }
    }
    
    private func setupSearchBar() {
           searchBar.delegate = self
           searchBar.placeholder = "Search by product name, quantity, or price"
           navigationItem.titleView = searchBar
       }

    
}


extension ProductListVC {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredProducts.count : products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:  String(describing: TableViewCell.self), for: indexPath) as! TableViewCell
        let data = isSearching ? filteredProducts[indexPath.row] : products[indexPath.row]
        cell.productName.text = "Product Name: \(data.productname)"
        cell.quantity.text = "Quantity: \(data.quantity)"
        cell.price.text = "Price: \(data.price)"
        cell.productDetail.text = "Detail: \(data.productDetail)"
        
        
        let imageUrl = data.productImageUrl

        cell.productImage.sd_setImage(with: URL(string: imageUrl), placeholderImage: UIImage(named: "logo"))
        
        cell.acceptBtn.isHidden = true
        cell.acceptBtn.tag = indexPath.row
        cell.heartBtn.tag = indexPath.row

        let userType = UserDefaultsManager.shared.getUserType()
        
        if userType != UserType.admin.rawValue {
            if data.adminEmail != UserDefaultsManager.shared.getEmail() {
                cell.acceptBtn.isHidden = false
                if self.arrSoldOutProducts.filter({ $0.productname == data.productname && $0.quantity == data.quantity }).count > 0 {
                    cell.acceptBtn.setTitle("Sold Out", for: .normal)
                    cell.acceptBtn.backgroundColor = .red
                } else {
                    cell.acceptBtn.setTitle("Bid", for: .normal)
                    cell.acceptBtn.backgroundColor = colorThemeGreen
                    cell.acceptBtn.addTarget(self, action: #selector(openRaiseRequest(_:)), for: .touchUpInside)
                }
            }
            cell.heartBtn.isHidden = false
            cell.heartBtn.addTarget(self, action: #selector(managewishlistRequest(_:)), for: .touchUpInside)
            let isAddedToWishlist = arrWishlistProducts.filter({ $0.product_id == data.product_id }).count
            cell.heartBtn.setImage((isAddedToWishlist == 0) ? .init(systemName: "heart") : .init(systemName: "heart.fill"), for: .normal)
        } else {
            cell.heartBtn.isHidden = true
            cell.acceptBtn.isHidden = false
            cell.acceptBtn.backgroundColor = .red
            cell.acceptBtn.setTitle("Delete", for: .normal)
            cell.acceptBtn.addTarget(self, action: #selector(deleteRequest(_:)), for: .touchUpInside)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 155
    }
    
    @objc func managewishlistRequest(_ sender: UIButton) {
        let data = isSearching ? filteredProducts[sender.tag] : products[sender.tag]
        if let index = arrWishlistProducts.firstIndex(where: { $0.product_id == data.product_id }) {
            FireStoreManager.shared.removeFromWishlist(userID: UserDefaultsManager.shared.getDocumentId(), product: data) { result in
                if result {
                    self.arrWishlistProducts.remove(at: index)
                    self.tableView.reloadData()
                }
            }
        } else {
            FireStoreManager.shared.addIntoWishlist(userID: UserDefaultsManager.shared.getDocumentId(), product: data) { result in
                if result {
                    self.arrWishlistProducts.append(data)
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    @objc func openRaiseRequest(_ sender: UIButton) {
        let data = isSearching ? filteredProducts[sender.tag] : products[sender.tag]
        let vc = self.storyboard?.instantiateViewController(withIdentifier:  "BidProductVC" ) as! BidProductVC
        vc.productData = data
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func deleteRequest(_ sender: UIButton) {
        let data = isSearching ? filteredProducts[sender.tag] : products[sender.tag]
        let alert = UIAlertController(title: "Alert", message: "Do you want to delete \(data.productname) product?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .default))
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            FireStoreManager.shared.deleteSpecificProduct(DocumentID: data.adminId, productDocumentID: data.product_id) { error in
                if let err = error {
                    showAlerOnTop(message: err.localizedDescription)
                } else {
                    showAlerOnTop(message: "Product Deleted successfully")
                    self.products = self.products.filter({ $0.product_id != data.product_id })
                    self.filteredProducts = self.filteredProducts.filter({ $0.product_id != data.product_id })
                    self.tableView.reloadData()
                }
            }
        }))
        self.present(alert, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
           if searchText.isEmpty {
               isSearching = false
               filteredProducts = []
           } else {
               isSearching = true
               filteredProducts = products.filter { product in
                   return product.productname.lowercased().contains(searchText.lowercased()) ||
                          "\(product.quantity)".contains(searchText) ||
                          "\(product.price)".contains(searchText)
               }
           }
           tableView.reloadData()
       }

       func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
           searchBar.text = ""
           isSearching = false
           filteredProducts = []
           tableView.reloadData()
           searchBar.resignFirstResponder()
       }
}

