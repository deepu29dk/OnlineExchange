//
//  EncryptionModel.swift
//  News On Air
//
//  Created by Savan Ankola on 18/01/24.
//

import Foundation
import CommonCrypto

class AesSslPinManager {
    
    static let shared = AesSslPinManager()
    private let key = "H/bjenlgQFuFBl0FIZ3uPKSrrJnE63W0adPQRz09Hro="
    private let iv = "i+v/V//+AUrVB9fc76ephQ=="
    let sslPinningKeysUF = "sslPinningKeys"
    let sslPinningJsonUF = "sslPinningJson"
  
    func getJsonString() -> String {
        let jsonData: [String: Any] = [
            "data": [
                [
                    "domain": "newsonair.gov.in",
                    "pin": "sha256/E3tYcwo9CiqATmKtpMLW5V+pzIq+ZoDmpXSiJlXGmTo="
                ],
                [
                    "domain": "prasarbharati.org",
                    "pin": "sha256/N2oacIKlk9zMINVh0Rnpq40w8RzDIdCjf6QfDfKE4Bw="
                ]
            ]
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonData, options: .sortedKeys)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Original JSON String: \(jsonString)")
                let encryptedString = self.aesEncryptToString(jsonString)
                print("\nEncrypted JSON String: \(encryptedString)")
                return encryptedString
            } else {
                print("Failed to convert JSON data to string")
                return ""
            }
        } catch {
            print("Error converting JSON to string: \(error.localizedDescription)")
            return ""
        }
    }
    
    // Convert JSON string to Data
    func jsonStingToArrPin(jsonString: String) -> [String] {
        let decryptedStr = self.aesDecryptFromString(jsonString)
        print("\nDecrypted JSON String: ", decryptedStr)
        
        if let jsonData = decryptedStr.data(using: .utf8) {
            do {
                // Convert Data to Dictionary
                if let jsonDictionary = try JSONSerialization.jsonObject(with: jsonData, options: .fragmentsAllowed) as? [String: Any] {
                    print("JSON Dictionary: \(jsonDictionary)")
                    
                    // Accessing values
                    if let arr = jsonDictionary["data"] as? [[String: Any]] {
                        print("arr: \(arr)")
                        var arrPin : [String] = []
                        for dic in arr {
                            let fingerprint = dic["pin"] as? String ?? ""
                            if !fingerprint.isEmpty {
                                print("pin: ", fingerprint)
                                arrPin.append(fingerprint)
                            }
                        }
                        return arrPin
                    } else {
                        return []
                    }
                } else {
                    return []
                }
            } catch {
                print("Failed to convert JSON string to dictionary: \(error.localizedDescription)")
                return []
            }
        } else {
            print("Invalid JSON string")
            return []
        }
    }
    
    func localSSLKeyUpdate() {
        if (UserDefaults.standard.string(forKey: self.sslPinningJsonUF) == nil) ||
            ((UserDefaults.standard.stringArray(forKey: self.sslPinningKeysUF) ?? []).count == 0) {
            let strJson = self.getJsonString()
            UserDefaults.standard.setValue(strJson, forKey: self.sslPinningJsonUF)
            let arrPin = self.jsonStingToArrPin(jsonString: strJson)
            if arrPin.count > 0 {
                UserDefaults.standard.setValue(arrPin, forKey: self.sslPinningKeysUF)
            }
            UserDefaults.standard.synchronize()
        }
    }
    
    func verifyLatestSSLKeyData(keyJson : String) {
        if (UserDefaults.standard.string(forKey: self.sslPinningJsonUF) ?? "") != keyJson && !keyJson.isEmpty {
            let arrPin = AesSslPinManager.shared.jsonStingToArrPin(jsonString: keyJson)
            if arrPin.count > 0 {
                UserDefaults.standard.setValue(keyJson, forKey: self.sslPinningJsonUF)
                UserDefaults.standard.setValue(arrPin, forKey: self.sslPinningKeysUF)
            }
            UserDefaults.standard.synchronize()
        }
    }
   
    // AES Encryption that returns a Base64-encoded string
    func aesEncryptToString(_ input: String) -> String {
        
        guard let dataToEncrypt = input.data(using: .utf8),
              let keyData = Data(base64Encoded: key),
              let ivData = Data(base64Encoded: iv) else {
            return ""
        }
        
        guard keyData.count == kCCKeySizeAES256, ivData.count == kCCBlockSizeAES128 else {
            return ""
        }
        
        let cryptLength = size_t(dataToEncrypt.count + kCCBlockSizeAES128)
        var cryptData = Data(count: cryptLength)
        
        var bytesEncrypted = 0
        
        let status = cryptData.withUnsafeMutableBytes { cryptBytes in
            dataToEncrypt.withUnsafeBytes { dataBytes in
                ivData.withUnsafeBytes { ivBytes in
                    keyData.withUnsafeBytes { keyBytes in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES128),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, kCCKeySizeAES256,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress, dataToEncrypt.count,
                            cryptBytes.baseAddress, cryptLength,
                            &bytesEncrypted)
                    }
                }
            }
        }
        
        if status == kCCSuccess {
            cryptData.removeSubrange(bytesEncrypted..<cryptData.count)
            return cryptData.base64EncodedString()
        } else {
            return ""
        }
    }
    
    // AES Decryption that takes a Base64-encoded string and returns the original text
    func aesDecryptFromString(_ encryptedBase64String: String) -> String {
        guard let encryptedData = Data(base64Encoded: encryptedBase64String),
              let keyData = Data(base64Encoded: key),
              let ivData = Data(base64Encoded: iv) else {
            return ""
        }
        
        let cryptLength = size_t(encryptedData.count + kCCBlockSizeAES128)
        var cryptData = Data(count: cryptLength)
        
        var bytesDecrypted = 0
        
        let status = cryptData.withUnsafeMutableBytes { cryptBytes in
            encryptedData.withUnsafeBytes { encryptedBytes in
                ivData.withUnsafeBytes { ivBytes in
                    keyData.withUnsafeBytes { keyBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES128),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, kCCKeySizeAES256,
                            ivBytes.baseAddress,
                            encryptedBytes.baseAddress, encryptedData.count,
                            cryptBytes.baseAddress, cryptLength,
                            &bytesDecrypted)
                    }
                }
            }
        }
        
        if status == kCCSuccess {
            cryptData.removeSubrange(bytesDecrypted..<cryptData.count)
            return String(data: cryptData, encoding: .utf8) ?? ""
        } else {
            return ""
        }
    }
}

extension String {
    var encryptStr: String {
        return AesSslPinManager.shared.aesEncryptToString(self)
    }
    
    var decryptStr: String {
        return AesSslPinManager.shared.aesDecryptFromString(self)
    }
}
