//
//  IPaImgur+Error.swift
//  IPaImgur
//
//  Created by IPa Chen on 2020/7/25.
//

import UIKit

extension IPaImgur {
    static let errorDomain = "com.ipaimgur.error"
    static let oauthResponseError:Error = NSError(domain: errorDomain, code: 1000, userInfo: [NSLocalizedDescriptionKey:"login response format not correct!"])
}
