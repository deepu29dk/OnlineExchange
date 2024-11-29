
import Foundation
struct SignupModel {
    let fullname: String
    let email: String
    let password: String
    let userType: String

    init(fullname: String, email: String, password: String, userType: String) {
        self.fullname = fullname.capitalized
        self.email = email.lowercased()
        self.password = password
        self.userType = userType
    }

    func toDictionary() -> [String: Any] {
        return [
            "fullname": fullname,
            "email": email,
            "password": password,
            "userType": userType
        ]
    }

    init?(dictionary: [String: Any]) {
        guard let fullname = dictionary["fullname"] as? String,
              let email = dictionary["email"] as? String,
              let password = dictionary["password"] as? String,
              let userType = dictionary["userType"] as? String else {
            return nil
        }
        
        self.fullname = fullname.capitalized
        self.email = email.lowercased()
        self.password = password
        self.userType = userType
    }
}
