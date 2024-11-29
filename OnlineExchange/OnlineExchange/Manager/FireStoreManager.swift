
import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import Firebase


class FireStoreManager {
    
    public static let shared = FireStoreManager()
    var hospital = [String]()
    var db: Firestore!
    var dbRef : CollectionReference!
    let USER_TABLE_NAME = "Users"
    let AcceptedOrder_TABLE_NAME = "AcceptedOrder"
    let PaymentHistory_TABLE_NAME = "PaymentHistory"

    init() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
        dbRef = db.collection("Users")
    }
    
    func signUp(email:String, signupData: SignupModel) {
        
        self.checkAlreadyExistAndSignup(email: email, signupData: signupData)
    }
    
    func login(email:String,password:String,completion: @escaping (Bool)->()) {
        let  query = db.collection("Users").whereField("email", isEqualTo: email)
        
        query.getDocuments { (querySnapshot, err) in
            
            if(querySnapshot?.count == 0) {
                showAlerOnTop(message: "Email id not found!!")
            }else {
                
                for document in querySnapshot!.documents {
                    print("doclogin = \(document.documentID)")
                    UserDefaults.standard.setValue("\(document.documentID)", forKey: "documentId")
                    
                    if let pwd = document.data()["password"] as? String{
                        
                        if(pwd == password) {
                            
                            
                            let email = document.data()["email"] as? String ?? ""
                            let userType = document.data()["userType"] as? String ?? ""
                            let fullname = document.data()["fullname"] as? String ?? ""
                            
                            UserDefaultsManager.shared.saveData(email: email, userType: userType, fullname: fullname)
                            completion(true)
                            
                        }else {
                            showAlerOnTop(message: "Password doesn't match")
                        }
                        
                        
                    }else {
                        showAlerOnTop(message: "Something went wrong!!")
                    }
                }
            }
        }
    }
    
    func checkAlreadyExistAndSignup(email:String, signupData: SignupModel) {
        
        getQueryFromFirestore(field: "email", compareValue: email) { querySnapshot in
            
            print(querySnapshot.count)
            
            if(querySnapshot.count > 0) {
                showAlerOnTop(message: "This Email is Already Registerd!!")
            }else {
                
                let data = signupData.toDictionary()
                
                self.addDataToFireStore(data: data) { _ in
                    
                    showOkAlertAnyWhereWithCallBack(message: "Registration Success!!") {
                        
                        DispatchQueue.main.async {
                            SceneDelegate.shared?.openHomeOrLogin()
                        }
                        
                    }
                    
                }
                
            }
        }
    }
    
    func getQueryFromFirestore(field:String,compareValue:String,completionHandler:@escaping (QuerySnapshot) -> Void){
        
        dbRef.whereField(field, isEqualTo: compareValue).getDocuments { querySnapshot, err in
            
            if let err = err {
                
                showAlerOnTop(message: "Error getting documents: \(err)")
                return
            }else {
                
                if let querySnapshot = querySnapshot {
                    return completionHandler(querySnapshot)
                }else {
                    showAlerOnTop(message: "Something went wrong!!")
                }
                
            }
        }
        
    }
    
    func addDataToFireStore(data: [String: Any], completionHandler: @escaping (Any) -> Void) {
        let dbr = db.collection("Users")
        dbr.addDocument(data: data) { err in
            if let err = err {
                showAlerOnTop(message: "Error adding document: \(err)")
            } else {
                completionHandler("success")
            }
        }
    }
    
    func getPassword(email:String,password:String,completion: @escaping (String)->()) {
        let  query = db.collection("Users").whereField("email", isEqualTo: email)
        
        query.getDocuments { (querySnapshot, err) in
            
            if(querySnapshot?.count == 0) {
                showAlerOnTop(message: "Email id not found!!")
            }else {
                
                for document in querySnapshot!.documents {
                    print("doclogin = \(document.documentID)")
                    UserDefaults.standard.setValue("\(document.documentID)", forKey: "documentId")
                    if let pwd = document.data()["password"] as? String{
                        completion(pwd)
                    }else {
                        showAlerOnTop(message: "Something went wrong!!")
                    }
                }
            }
        }
    }
    
    func addPaymentHistory(product: ProductModel, completionHandler: @escaping (Bool) -> ()) {
        var updatedProduct = product
        updatedProduct.paymentStatus = "Done"
        let ref = db.collection(PaymentHistory_TABLE_NAME).document(product.product_id)
        ref.setData(updatedProduct.toDictionary(), completion: { error in
            if let error = error {
                print("Error while addPaymentHistory Collection: \(error.localizedDescription)")
                completionHandler(false)
            } else {
                print("successfully addPaymentHistory ID: \(product.productname)")
                completionHandler(true)
            }
        })
        
        let userRequestRef = self.dbRef.document(product.userId).collection("BidAcceptedByOwnerOfUser").document(product.product_id)
        userRequestRef.setData(updatedProduct.toDictionary()) { error in
            if let error = error {
                print("Error while update BidAcceptedByOwnerOfUser table Collection: \(error.localizedDescription)")
//                completionHandler(false)
            } else {
                print("successfully BidAcceptedByOwnerOfUser table updated ID: \(product.productname)")
//                completionHandler(true)
            }
        }
    }
    
    func addToAcceptedOrderList(product: ProductModel, completionHandler: @escaping (Bool) -> ()) {
        let ref = db.collection(AcceptedOrder_TABLE_NAME).document(product.product_id)
        var updatedProduct = product
        updatedProduct.isSoldOut = true
        ref.setData(updatedProduct.toDictionary(), completion: { error in
            if let error = error {
                print("Error while adding product to Accepted Order List Collection: \(error.localizedDescription)")
                completionHandler(false)
            } else {
                print("Product successfully added to Accepted Order List Collection with ID: \(product.productname)")
                completionHandler(true)
            }
        })
    }
    
    func addProductDetail(documentID: String, product: ProductModel, completionHandler: @escaping (Bool) -> ()) {
        let ref = dbRef.document(documentID)
        
        ref.getDocument { document, error in
            if let error = error {
                print("Error fetching document: \(error.localizedDescription)")
                completionHandler(false)
                return
            }
            
            if let document = document, document.exists {
                let productDocRef = self.dbRef.document(documentID).collection("Products").document()
                
                let productId = productDocRef.documentID
                
                var updatedProduct = product
                updatedProduct = ProductModel(
                    productname: product.productname,
                    adminId: product.adminId,
                    price: product.price,
                    quantity: product.quantity,
                    productImageUrl: product.productImageUrl,
                    userId: product.userId,
                    availableQuantity: product.availableQuantity,
                    productDetail: product.productDetail,
                    adminEmail: product.adminEmail,
                    userEmail: product.userEmail,
                    product_id: productId, bidPrice: product.bidPrice, added_time: product.added_time
                )
                
                let productData = updatedProduct.toDictionary()
                
                productDocRef.setData(productData) { error in
                    if let error = error {
                        print("Error adding product to Products collection: \(error.localizedDescription)")
                        completionHandler(false)
                    } else {
                        print("Product successfully added to Products collection with ID: \(productId)")
                        completionHandler(true)
                    }
                }
            } else {
                print("Document does not exist")
                completionHandler(false)
            }
        }
    }
    
    
    func processProductRequestAndUpdateBid(
        documentID: String,
        adminId: String,
        product: ProductModel,
        newBidPrice: String,
        bidproduct_id: String,
        productDocumentId: String,
        completionHandler: @escaping (Bool) -> ()
    ) {
        let productDocRef = self.dbRef.document(documentID).collection("RequestBid").document(productDocumentId)
        let productId = productDocumentId
        
        var updatedProduct = product
        updatedProduct.bidPrice = newBidPrice
        updatedProduct.product_id = productId

        let productData = updatedProduct.toDictionary()
        
        productDocRef.setData(productData) { error in
            if let error = error {
                print("Error adding product to RequestBid collection: \(error.localizedDescription)")
                completionHandler(false)
                return
            }
            
            let userRef = self.dbRef.document(adminId).collection("RequestBidFromUser").document(productId)
            
            userRef.setData(productData) { error in
                if let error = error {
                    print("Error adding request to RequestBidFromUser: \(error.localizedDescription)")
                    completionHandler(false)
                } else {
                    let productDocRef = self.dbRef.document(adminId).collection("Products").document(bidproduct_id)
                    let updatedData: [String: Any] = ["bidPrice": newBidPrice]
                    
                    productDocRef.updateData(updatedData) { error in
                        if let error = error {
                            print("Error updating bidPrice in database: \(error.localizedDescription)")
                            completionHandler(false)
                        } else {
                            print("Successfully updated bidPrice in database")
                            completionHandler(true)
                        }
                    }
                }
            }
        }
    }

    func deleteRemainingBidRequests(
        adminId: String,
        productID: String,
        completionHandler: @escaping (Bool) -> ()
    ) {
        let requestBidCollection = self.dbRef.document(adminId).collection("RequestBidFromUser")
        
        let documentIDPattern = "\(productID)-"

        requestBidCollection.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error.localizedDescription)")
                completionHandler(false)
                return
            }
            
            let batch = Firestore.firestore().batch()
            
            for document in querySnapshot!.documents {
                if document.documentID.starts(with: documentIDPattern) {
                    batch.deleteDocument(document.reference)
                }
            }

            batch.commit { error in
                if let error = error {
                    print("Error deleting documents: \(error.localizedDescription)")
                    completionHandler(false)
                } else {
                    print("Successfully deleted remaining bid requests.")
                    completionHandler(true)
                }
            }
        }
    }
    
//    func updateHighestBidPrice(productId: String, adminId: String, product: ProductModel, completionHandler: @escaping (Bool) -> ()) {
//        let productDocRef = self.dbRef.document(adminId).collection("Products").document(productId)
//        
//        let productId = productDocRef.documentID
//        
//        var updatedProduct = product
//        
//        updatedProduct = ProductModel(
//            productname: product.productname,
//            adminId: product.adminId,
//            price: product.price,
//            quantity: product.quantity,
//            productImageUrl: product.productImageUrl,
//            userId: product.userId,
//            availableQuantity: product.availableQuantity,
//            productDetail: product.productDetail,
//            adminEmail: product.adminEmail,
//            userEmail: product.userEmail,
//            product_id: productId, bidPrice: product.bidPrice
//        )
//        
//        let productData = updatedProduct.toDictionary()
//        
//        productDocRef.setData(productData) { error in
//            if let error = error {
//                print("Error adding product to Products collection: \(error.localizedDescription)")
//                completionHandler(false)
//            } else {
//                
//                let userRef = self.dbRef.document(product.adminId).collection("RequestBidFromUser").document(updatedProduct.product_id)
//                
//                userRef.setData(productData) { error in
//                    if let error = error {
//                        print("Error adding request to ProductRequestToManager: \(error.localizedDescription)")
//                        completionHandler(false)
//                    } else {
//                        print("Request successfully added to ProductRequestToManager collection")
//                        completionHandler(true)
//                    }
//                    
//                }
//            }
//        }
//    }
    
    func deleteSpecificProduct(DocumentID: String, productDocumentID: String, completionHandler: @escaping (Error?) -> ()) {
        // Get the reference to the specific admin document and its "Products" sub-collection
        let productRef = dbRef.document(DocumentID).collection("Products").document(productDocumentID)
        
        // Delete the specific product
        productRef.delete { error in
            if let error = error {
                print("Error deleting product: \(error.localizedDescription)")
                completionHandler(error)
            } else {
                print("Product \(productDocumentID) deleted successfully.")
                completionHandler(nil)
            }
        }
    }
    
    func getPaymentHistoryList(completionHandler: @escaping ([ProductModel]?, Error?) -> ()) {
        let ref = db.collection(PaymentHistory_TABLE_NAME)

        ref.getDocuments { querySnapshot, error in
            if let error = error {
                print("Error fetching bid requests: \(error.localizedDescription)")
                completionHandler(nil, error)
                return
            }
            
            guard let snapshot = querySnapshot else {
                print("No product requests found")
                completionHandler([], nil)
                return
            }
            
            let productRequests = snapshot.documents.compactMap { document -> ProductModel? in
                let data = document.data()
                return ProductModel(dictionary: data)
            }
            
            completionHandler(productRequests, nil)
        }
    }
    
    func getAcceptedProductList(completionHandler: @escaping ([ProductModel]?, Error?) -> ()) {
        let ref = db.collection(AcceptedOrder_TABLE_NAME)
       
        ref.getDocuments { querySnapshot, error in
            if let error = error {
                print("Error fetching bid requests: \(error.localizedDescription)")
                completionHandler(nil, error)
                return
            }
            
            guard let snapshot = querySnapshot else {
                print("No product requests found")
                completionHandler([], nil)
                return
            }
            
            let productRequests = snapshot.documents.compactMap { document -> ProductModel? in
                let data = document.data()
                return ProductModel(dictionary: data)
            }
            
            completionHandler(productRequests, nil)
        }
    }
    
    func getAdminProducts(completionHandler: @escaping ([ProductModel]?, Error?) -> ()) {
        var productsArray: [ProductModel] = []
        
        dbRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching admin users: \(error.localizedDescription)")
                completionHandler(nil, error)
                return
            }
            
            guard let snapshot = snapshot else {
                completionHandler(nil, nil)
                return
            }
            
            let group = DispatchGroup()
            
            for document in snapshot.documents {
                group.enter()
                
                let productsRef = self.dbRef.document(document.documentID).collection("Products")
                productsRef.getDocuments { (productSnapshot, error) in
                    if let error = error {
                        print("Error fetching products: \(error.localizedDescription)")
                        group.leave()
                        return
                    }
                    if let productSnapshot = productSnapshot {

                        for productDocument in productSnapshot.documents {
                            let productData = productDocument.data()
                            if let product = ProductModel(dictionary: productData) {
                                print("product - ", product.adminId, " document.documentID - ", document.documentID, " added time : ", product.added_time)

                                productsArray.append(product)
                            }
                        }
                    }
                    
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                completionHandler(productsArray, nil)
            }
        }
    }
    
    func getBidRequests(forUserId userId: String, completionHandler: @escaping ([ProductModel]?, Error?) -> ()) {
        let userRef = self.dbRef.document(userId).collection("RequestBidFromUser")
        
        userRef.getDocuments { querySnapshot, error in
            if let error = error {
                print("Error fetching bid requests: \(error.localizedDescription)")
                completionHandler(nil, error)
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No product requests found")
                completionHandler([], nil)
                return
            }
            
            let productRequests = documents.compactMap { document -> ProductModel? in
                let data = document.data()
                return ProductModel(dictionary: data)
            }
            
            completionHandler(productRequests, nil)
        }
    }
    
    func acceptProductRequest(request: ProductModel, completionHandler: @escaping (Bool) -> ()) {
        let ref = self.dbRef.document(UserDefaultsManager.shared.getDocumentId()).collection("RequestBidFromUser")
        
        ref.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error.localizedDescription)")
                completionHandler(false)
                return
            }
            
            guard let querySnapshot = querySnapshot, !querySnapshot.isEmpty else {
                print("No documents found in ProductRequest collection")
                completionHandler(false)
                return
            }
            
            let userRef = self.dbRef.document(UserDefaultsManager.shared.getDocumentId())
            
            let rejectProductRef = userRef.collection("BidAcceptedByOwner").document(request.product_id)
            
            rejectProductRef.setData(request.toDictionary()) { error in
                if let error = error {
                    print("Error adding product to RejectProduct collection: \(error.localizedDescription)")
                    completionHandler(false)
                    return
                } else {
                    print("Product successfully added to RejectProduct collection")
                    
                    let userRequestRef = self.dbRef.document(request.userId).collection("BidAcceptedByOwnerOfUser").document(request.product_id)
                    
                    userRequestRef.setData(request.toDictionary()) { error in
                        if let error = error {
                            print("Error adding request to user's RejectProductRequest collection: \(error.localizedDescription)")
                            completionHandler(false)
                            return
                        } else {
                            // Step 3: Delete the document from "ProductRequest" collection
                            ref.document(request.product_id).delete { error in
                                if let error = error {
                                    print("Error deleting product request from ProductRequest collection: \(error.localizedDescription)")
                                    completionHandler(false)
                                } else {
                                    let userref = self.dbRef.document(request.userId).collection("RequestBid")
                                    
                                    userref.document(request.product_id ?? "").delete { error in
                                        if let error = error {
                                            print("Error deleting product request from ProductRequest collection: \(error.localizedDescription)")
                                            completionHandler(false)
                                        } else {
                                            
                                            print("Product request successfully deleted from ProductRequest collection")
                                            // completionHandler(true)
                                        }
                                    }
                                    
                                    print("Product request successfully deleted from ProductRequest collection")
                                    let requestproductId = "\(request.productname)-\(request.price)-\(request.quantity)"
                                    self.deleteRemainingBidRequests(adminId: request.adminId, productID: requestproductId) { success in
                                        if success {
                                            print("Product quantity successfully updated in warehouse")
                                            completionHandler(true)
                                        } else {
                                            print("Failed to update product quantity in warehouse")
                                            completionHandler(false)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
        }
    }
    
    
    func updateAdminProductQuantity(adminID: String, product: ProductModel, completionHandler: @escaping (Bool) -> ()) {
        let warehouseRef = dbRef.document(adminID).collection("Products")
        
        warehouseRef.whereField("productname", isEqualTo: product.productname)
            .whereField("price", isEqualTo: product.price)
            .whereField("availableQuantity", isEqualTo: product.availableQuantity)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching product documents: \(error.localizedDescription)")
                    completionHandler(false)
                    return
                }
                
                guard let querySnapshot = querySnapshot, !querySnapshot.isEmpty else {
                    print("No matching products found")
                    completionHandler(false)
                    return
                }
                
                // Assuming that there will be only one matching product
                if let document = querySnapshot.documents.first {
                    var productData = document.data()
                    let productDocID = document.documentID
                    
                    // Retrieve the current quantity and update it
                    if let currentQuantityString = productData["quantity"] as? String, let currentQuantity = Int(currentQuantityString) {
                        let productQuantityString = product.quantity
                        let productQuantity = Int(productQuantityString) ?? 0
                        
                        let newQuantity = currentQuantity - productQuantity
                        print("currentQuantity: \(currentQuantity), productQuantity: \(productQuantity), newQuantity: \(newQuantity)")
                        
                        // Update the product's quantity
                        productData["quantity"] = "\(newQuantity)"
                        
                        // Update the document in Firestore with the new data
                        warehouseRef.document(productDocID).updateData(productData) { error in
                            if let error = error {
                                print("Error updating product quantity: \(error.localizedDescription)")
                                completionHandler(false)
                            } else {
                                print("Product quantity updated successfully")
                                completionHandler(true)
                            }
                        }
                    } else {
                        print("Invalid or missing current quantity")
                        completionHandler(false)
                    }
                } else {
                    print("Product not found")
                    completionHandler(false)
                }
            }
    }
    
    
    func rejectProductRequest(request: ProductModel, completionHandler: @escaping (Bool) -> ()) {
        let ref = self.dbRef.document(UserDefaultsManager.shared.getDocumentId()).collection("RequestBidFromUser")
        
        ref.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error.localizedDescription)")
                completionHandler(false)
                return
            }
            
            guard let querySnapshot = querySnapshot, !querySnapshot.isEmpty else {
                print("No documents found in ProductRequest collection")
                completionHandler(false)
                return
            }
            
            let userRef = self.dbRef.document(UserDefaultsManager.shared.getDocumentId())
            
            let rejectProductRef = userRef.collection("BidRejectedByOwner").document(request.product_id)
            
            rejectProductRef.setData(request.toDictionary()) { error in
                if let error = error {
                    print("Error adding product to RejectProduct collection: \(error.localizedDescription)")
                    completionHandler(false)
                    return
                } else {
                    print("Product successfully added to RejectProduct collection")
                    
                    let userRequestRef = self.dbRef.document(request.userId).collection("BidRejectedByOwnerOfUser").document(request.product_id)
                    
                    userRequestRef.setData(request.toDictionary()) { error in
                        if let error = error {
                            print("Error adding request to user's RejectProductRequest collection: \(error.localizedDescription)")
                            completionHandler(false)
                            return
                        } else {
                            ref.document(request.product_id).delete { error in
                                if let error = error {
                                    print("Error deleting product request from ProductRequest collection: \(error.localizedDescription)")
                                    completionHandler(false)
                                } else {
                                    let userref = self.dbRef.document(request.userId).collection("RequestBid")
                                    
                                    userref.document(request.product_id ?? "").delete { error in
                                        if let error = error {
                                            print("Error deleting product request from ProductRequest collection: \(error.localizedDescription)")
                                            completionHandler(false)
                                        } else {
                                            
                                            print("Product request successfully deleted from ProductRequest collection")
                                            completionHandler(true)
                                        }
                                    }
                                    
                                    print("Product request successfully deleted from ProductRequest ")
                                }
                            }
                        }
                    }
                }
            }
            
        }
    }
    
    func getAllRequestProductRecord(forUserId userId: String, collectionStatus: String, completionHandler: @escaping ([ProductModel]?, Error?) -> ()){
        let userRef = self.dbRef.document(userId).collection(collectionStatus)
        
        userRef.getDocuments { querySnapshot, error in
            if let error = error {
                print("Error fetching bid requests: \(error.localizedDescription)")
                completionHandler(nil, error)
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No product requests found")
                completionHandler([], nil)
                return
            }
            
            let productRequests = documents.compactMap { document -> ProductModel? in
                let data = document.data()
                return ProductModel(dictionary: data)
            }
            
            completionHandler(productRequests, nil)
        }
    }
    
    
    func getChatList(userEmail: String, completionHandler: @escaping ([QueryDocumentSnapshot]?, Error?) -> Void) {
        
        let lastMessages = self.db.collection("LastMessages")
        
        let query = lastMessages.order(by: "dateSent", descending: true).limit(to: 1000)
        
        // Add a snapshot listener to the query
        query.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error)")
                completionHandler(nil, error)
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                completionHandler(nil, nil)
                return
            }
            
            let filteredDocuments = documents.filter { document in
                document.documentID.contains(userEmail)
            }
            
            completionHandler(filteredDocuments, nil)
        }
        
    }
    
    func getChatListForAdmin(completionHandler: @escaping ([QueryDocumentSnapshot]?, Error?) -> Void) {
        
        let lastMessages = self.db.collection("LastMessages")

        let query = lastMessages.order(by: "dateSent", descending: true).limit(to: 1000)
        
        query.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error)")
                completionHandler(nil, error)
                return
            }
            
            let documents = querySnapshot?.documents
            completionHandler(documents, nil)
        }
    }
    
    
    
    func getProductWishList(userID: String, searchStr: String, completionHandler: @escaping ([ProductModel]?, Error?) -> ()) {
        let userRef = self.dbRef.document(userID).collection("wishlist")
        
        userRef.getDocuments { querySnapshot, error in
            if let error = error {
                print("Error fetching bid requests: \(error.localizedDescription)")
                completionHandler(nil, error)
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No product requests found")
                completionHandler([], nil)
                return
            }
            
            let productRequests = documents.compactMap { document -> ProductModel? in
                let data = document.data()
                return ProductModel(dictionary: data)
            }
            
            completionHandler(productRequests, nil)
        }
    }

    func addIntoWishlist(userID: String, product: ProductModel, completionHandler: @escaping (Bool) -> ()) {
        let userRef = self.dbRef.document(userID).collection("wishlist").document(product.product_id)
        let productData = product.toDictionary()
        userRef.setData(productData) { error in
            if let error = error {
                print("Error adding product to Products collection: \(error.localizedDescription)")
                completionHandler(false)
            } else {
                print("Product successfully added in Wishlist")
                completionHandler(true)
            }
        }
    }

    func removeFromWishlist(userID: String, product: ProductModel, completionHandler: @escaping (Bool) -> ()) {
        let userRef = self.dbRef.document(userID).collection("wishlist")
        userRef.getDocuments { querySnapshot, error in
            if let error = error {
                print("Error fetching bid requests: \(error.localizedDescription)")
                completionHandler(false)
                return
            }
            guard let documents = querySnapshot?.documents else {
                print("No product requests found")
                completionHandler(false)
                return
            }
            for productDocument in documents {
                let productData = productDocument.data()
                if let productNew = ProductModel(dictionary: productData) {
                    if productNew.product_id == product.product_id {
                    let userRef = self.dbRef.document(userID).collection("wishlist").document(product.product_id)
                        userRef.delete { error in
                            if error == nil {
                                completionHandler(true)
                            } else {
                                print("Error while removing from wishlist: ", error?.localizedDescription ?? "")
                                completionHandler(false)
                            }
                        }
                    }
                }
            }
        }
    }
}

