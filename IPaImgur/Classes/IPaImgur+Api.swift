//
//  IPaImgur+Api.swift
//  IPaImgur
//
//  Created by IPa Chen on 2020/7/25.
//

import UIKit
import IPaURLResourceUI
import IPaImageTool

extension IPaImgur {
    public func apiData(_ api:String,method:IPaURLResourceUI.HttpMethod,headers:[String:String]?,params:[String:Any]?,complete:@escaping IPaURLResourceUIResultHandler) {
        var _headers = self.requestHeader!
        if let headers = headers {
            for (key,value) in headers {
                _headers[key] = value
            }
        }
        _ = self.resourceUI.apiData(api, method: method, headerFields: _headers, params: params, complete: complete)
        
    }
    public func apiUpload(_ api:String,method:IPaURLResourceUI.HttpMethod,headers:[String:String]?,params:[String:Any],file: IPaMultipartFile? = nil,complete:@escaping IPaURLResourceUIResultHandler) {
        var _headers = self.requestHeader!
        if let headers = headers {
            for (key,value) in headers {
                _headers[key] = value
            }
        }
        var files = [IPaMultipartFile]()
        if let file = file {
            files.append(file)
        }
        _ = self.resourceUI.apiFormDataUpload(api, method: method,headerFields:_headers , params: params, files: files, complete: complete)
    }
    public func credits(_ complete:@escaping ([String:Any]?)->()) {
        self.apiData("3/credits", method: .get, headers: nil, params: nil, complete: {
            result in
            switch result {
            case .success(let (_,responseData)):
                guard let rData = responseData.jsonData as? [String:Any],let data = rData["data"] as? [String:Any] else {
                    complete(nil)
                    return
                }
                complete(data)
            case .failure(_):
                complete(nil)
            }
        })
    }
    public func shareImage(_ imageId:String,title:String,topic:String?,mature:Bool?,tags:[String]?,complete:@escaping (String?)->()) {
        var params = [String:Any]()
        params["title"] = title
        if let topic = topic {
            params["topic"] = topic
        }
        params["terms"] = 1
        if let mature = mature {
            params["mature"] = mature ? 1 : 0
        }
        if let tags = tags {
            params["tags"] = tags.joined(separator: ",")
        }
        self.apiUpload("3/gallery/image/\(imageId)", method: .post, headers: nil, params: params, file: nil, complete: {
            result in
            switch result {
            case .success(let (_,responseData)):
                guard let rData = responseData.jsonData as? [String:Any],let success = rData["success"] as? Int,success == 1 else {
                    complete(nil)
                    return
                }
                complete("https://imgur.com/gallery/\(imageId)")
            case .failure(_):
                complete(nil)
            }
        })
        
        
    }
    public func upload(_ image:UIImage,quality:CGFloat,album:String?,filename:String,title:String,description:String,complete:@escaping ([String:Any]?)->()) {
        
        let resizeImage = image.image(fitSize: CGSize(width: 1000, height: 1000))
        guard let data =  resizeImage.jpegData(compressionQuality: quality) else {
            complete(nil)
            return
        }
        let file = IPaMultipartFile(name: "image", mime: "image/jpg", fileName: filename, fileData: data)
        var params = ["type":"file","title":title,"description":description]
        if let album = album {
            params["album"] = album
        }
        self.apiUpload("3/upload", method: .post, headers: nil, params: ["image":data.base64EncodedString()], file: file, complete: {
            result in
            switch result {
            case .success(let (_,responseData)):
                guard let rData = responseData.jsonData as? [String:Any],let data = rData["data"] as? [String:Any] else {
                    complete(nil)
                    return
                }
                complete(data)
            case .failure(_):
                complete(nil)
            }
        })
    }
}
