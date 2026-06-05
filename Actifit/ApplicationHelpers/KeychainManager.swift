//
//  KeychainManager.swift
//  Actifit
//
//  Created by Ali Jaber on 20/09/2023.
//

import UIKit
import Security

class Keychain {
    class func save(_ data: Data, service: String) {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: KeychainKeys.actifitUser.rawValue,
        ] as CFDictionary
        
        let status = SecItemAdd(query, nil)
        
        if status != errSecSuccess {
            
        }
        
        if status == errSecDuplicateItem {
            let query = [
                kSecAttrService: service,
                kSecAttrAccount: KeychainKeys.actifitUser.rawValue,
                kSecClass: kSecClassGenericPassword
            ] as CFDictionary
            
            let attributesToUpdate = [ kSecValueData: data ] as CFDictionary
            
            var statusUpdated =  SecItemUpdate(query, attributesToUpdate)
            
            guard statusUpdated == errSecSuccess else {
                let errorMessage = SecCopyErrorMessageString(statusUpdated, nil)
                return
            }
        }
    }
    
    class func clearUser() {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: KeychainKeys.user.rawValue]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            print("Error deleting keychain items: \(status)")
        }
    }
    
    
    
    class func retrieve(service: String) -> Data? {
        let query = [
            kSecAttrService: KeychainKeys.user.rawValue,
            kSecAttrAccount: KeychainKeys.actifitUser.rawValue,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: kCFBooleanTrue,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        
        if status == noErr {
            return result as? Data
        } else {
            return nil
        }
        
    }
    
    class func createUniqueID() -> String {
        let uuid: CFUUID = CFUUIDCreate(nil)
        let cfStr: CFString = CFUUIDCreateString(nil, uuid)
        
        let swiftString: String = cfStr as String
        return swiftString
    }
    
    class func setObject<Object>(_ object: Object, service: String) throws where Object: Encodable {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            Keychain.save(data, service: service)
        } catch {
            throw ObjectSavableError.unableToEncode
        }
    }
    
    /// Getting Objects from Keychain
    /// - Parameter type: the type that it would decode to
    /// - Returns: the object after it is decoded
    class func getObject<Object>(castTo type: Object.Type, with service: String) throws -> Object where Object: Decodable {
        guard let data = Keychain.retrieve(service: service)
        else { throw ObjectSavableError.noValue }
        let decoder = JSONDecoder()
        do {
            let object = try decoder.decode(type, from: data)
            return object
        } catch {
            throw ObjectSavableError.unableToDecode
        }
    }
}
    

enum KeychainKeys: String {
    case user
    case actifitUser
}


enum ObjectSavableError: String, LocalizedError {
    case unableToEncode, noValue, unableToDecode

    var errorDescription: String? {
        switch self {
        case .unableToEncode:
            return "unable to encode"
        case .noValue:
            return "no value"
        case .unableToDecode:
            return "unable to decide"
        }
    }
}
