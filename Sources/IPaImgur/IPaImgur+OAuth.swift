//
//  IPaImgur+OAuth.swift
//  IPaImgur
//
//  Created by IPa Chen on 2020/7/25.
//

import UIKit
import IPaKeyChain
import IPaLog
extension IPaImgur {
    func handleLoginResponse(_ urlString
        :String,complete:(Result<UserInfo,Error>)->()) {
        //https://example.com/oauthcallback#access_token=ACCESS_TOKEN&token_type=Bearer&expires_in=3600
        let components = urlString.components(separatedBy: "#")
        guard let responseString = components.last else {
            complete(.failure(IPaImgur.oauthResponseError))
            return
        }
        let responseDataString = responseString.components(separatedBy: "&")
        let responseData = responseDataString.reduce( [String:String]()) { (dict, dataString) in
            var dict = dict
            let dataPairs = dataString.components(separatedBy: "=")
            guard dataPairs.count == 2,let key = dataPairs.first,let value = dataPairs.last else {
                
                return dict
            }
            dict[key] = value
            return dict
        }
        guard let token = responseData["access_token"],let  expireIn = responseData["expires_in"],let refreshToken = responseData["refresh_token"],let accountId = responseData["account_id"],let accountUsername = responseData["account_username"] else {
            if let errorString = responseData["error"] {
                let error = NSError(domain: IPaImgur.errorDomain, code: 2000, userInfo: [NSLocalizedDescriptionKey:errorString])
                complete(.failure(error))
            }
            else {
                complete(.failure(IPaImgur.oauthResponseError))
            }
            return
        }
        self.tokenData = IPaImgur.ImgurToken(token:token,expires:Date().timeIntervalSince1970 + (expireIn as NSString).doubleValue,refreshToken:refreshToken,accountId: accountId,username:accountUsername)
        
        
        
        complete(.success(UserInfo(accountId: accountId, username: accountUsername)))
    }
}
