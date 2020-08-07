//
//  IPaImgur.swift
//  IPaImgur
//
//  Created by IPa Chen on 2020/7/24.
//

import UIKit
import IPaKeyChain
import IPaLog
import IPaURLResourceUI
public class IPaImgur: NSObject {
    public static let shared = IPaImgur()
    static let keyChainService = "com.IPaImgur." + (Bundle.main.bundleIdentifier ?? "")
    public struct UserInfo {
        var accountId:String
        var username:String
    }
    struct ImgurToken: Codable {
        var token:String
        var expires:TimeInterval
        var refreshToken:String
        var accountId:String
        var username:String
    }
    var requestHeader:[String:String]! {
        var header = [String:String]()
        if let tokenData = tokenData {
            header["Authorization"] = "Bearer \(tokenData.token)"
        }
        else {
            header["Authorization"] = "Client-ID \(clientId)"
        }
        return header
    }
    var resourceUI:IPaURLResourceUI = {
        let resourceUI = IPaURLResourceUI()
        resourceUI.baseURL = "https://api.imgur.com/"
        return resourceUI
    }()
    var tokenData:ImgurToken? {
        get {
            let query = IPaKeyChainGenericPassword()
            query.secAttrService = IPaImgur.keyChainService
            query.matchLimit = .one
            query.secReturnAttributes = true
            query.secReturnData = true
            var data:AnyObject?
            let checkStatus = query.secItemCopyMatching(&data)
            if checkStatus == errSecSuccess {
                let result = IPaKeyChainGenericPassword(data:data as! [String:Any])
                let decoder = JSONDecoder()
                guard let tokenData = result.secValueData,let decodeTokenData = try? decoder.decode(ImgurToken.self, from: tokenData) else {
                    return nil
                }
                return decodeTokenData
            }
            return nil
        }
        set {
            let delChainQuery = IPaKeyChainGenericPassword()
            delChainQuery.secAttrService = IPaImgur.keyChainService
            _ = delChainQuery.secItemDelete()
            guard let newValue = newValue else {
                
                return
            }
           
            let addQuery = IPaKeyChainGenericPassword()
            addQuery.secAttrService = IPaImgur.keyChainService
            addQuery.secAttrAccount = newValue.username
            let encoder = JSONEncoder()
            addQuery.secValueData = try? encoder.encode(newValue)
            var data:AnyObject?
            if addQuery.secItemAdd(&data) == errSecSuccess {
                IPaLog("Imgur token saved!")
            
            }
            
        }
    }
    public var isLogin:Bool {
        return self.tokenData != nil
    }
    var clientId:String = ""
    var secret:String = ""
    var callbackUrl:String = ""
    public func register(_ clientId:String,secret:String,callbackUrl:String) {
        self.clientId = clientId
        self.secret = secret
        self.callbackUrl = callbackUrl
    }
    open func auth(from viewController:UIViewController,state:String,complete:@escaping (Result<UserInfo,Error>)->()) {
        
        let url = URL(string: "https://api.imgur.com/oauth2/authorize?client_id=\(self.clientId)&response_type=token&state=\(state)")!
        let webViewController = IPaImgurWebViewController()
        webViewController.request = URLRequest(url: url)
        let navigationController = UINavigationController(rootViewController: webViewController)
        webViewController.complete = complete
        viewController.present(navigationController, animated: true, completion: nil)
    }
    open func logout() {
        self.tokenData = nil
    }
    open func checkToken(_ complete:@escaping ()->()) {
        guard let tokenData = tokenData else {
            complete()
            return
        }
        let date = Date(timeIntervalSince1970:tokenData.expires)
        let today = Date()
        if today.compare(date) == .orderedDescending {
            //need refresh token
            self.apiUpload("oauth2/token", method: "POST", headers: nil, params: ["refresh_token":tokenData.refreshToken,"client_id":self.clientId,"client_secret":self.secret,"grant_type":"refresh_token"]) { (result) in
                switch result {
                case .success(let (_,responseData)):
                    guard let data = responseData as? [String:Any] ,let token = data["access_token"] as? String,let  expireIn = data["expires_in"] as? Double,let refreshToken = data["refresh_token"] as? String,let accountId = data["account_id"] as? Int,let accountUsername = data["account_username"] as? String else {
                        self.tokenData = nil
                        complete()
                        return
                    }
                    self.tokenData = IPaImgur.ImgurToken(token:token,expires:Date().timeIntervalSince1970 + expireIn,refreshToken:refreshToken,accountId: "\(accountId)",username:accountUsername)
                case .failure(_):
                    break
                }
                complete()
            }
            
            
        }
    }
}
