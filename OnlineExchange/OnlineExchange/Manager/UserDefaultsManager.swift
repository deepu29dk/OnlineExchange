 
import Foundation

class UserDefaultsManager  {
    
    static  let shared =  UserDefaultsManager()
    
    func clearUserDefaults() {
        
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()

            dictionary.keys.forEach
            {
                key in   defaults.removeObject(forKey: key)
            }
    }
        
    
    func loginBool() -> Bool{
        
        let email = getEmail()
        
        if(email.isEmpty) {
            return false
        }else {
           return true
        }
      
    }
     
    func getEmail()-> String {
        
        let email = UserDefaults.standard.string(forKey: "email") ?? ""
        
        print(email)
       return email
    }
   
    func getUserType()-> String {
       return UserDefaults.standard.string(forKey: "userType") ?? ""
    }
    
    func getFullname()-> String {
       return UserDefaults.standard.string(forKey: "fullname") ?? ""
    }
    
    func getDocumentId()-> String {
       return UserDefaults.standard.string(forKey: "documentId") ?? ""
    }
    
    func saveData(email:String, userType: String, fullname: String) {
        
        UserDefaults.standard.setValue(email, forKey: "email")
        UserDefaults.standard.setValue(userType, forKey: "userType")
        UserDefaults.standard.setValue(fullname, forKey: "fullname")
    }
  
    func clearData(){
        UserDefaults.standard.removeObject(forKey: "email")
        UserDefaults.standard.removeObject(forKey: "userType")
        UserDefaults.standard.removeObject(forKey: "fullname")
        UserDefaults.standard.removeObject(forKey: "documentId")
    }
}
