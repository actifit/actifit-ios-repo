//
//  PostCommentEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 01/10/2024.
//

import Foundation
enum PostCommentEndPoint {
    case postComment(author: String, permlink: String)
}

extension PostCommentEndPoint: Endpoint {
    var path: String {
        return ""
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var header: [String : String]? {
        return ["Content-Type" : "application/json"]
    }
    
    var body: [String : Any]? {
        switch self {
        case .postComment(let author, let permlink):
            let body = ["author": author, "permlink": permlink]

            return ["id":1,"jsonrpc":"2.0","method": "condenser_api.get_content_replies","params": body]
        }
    }

    var baseURLType: BaseURLTypes {
        return .hiveBlog
    }
    
    
}
