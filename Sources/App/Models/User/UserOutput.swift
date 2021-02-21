//
//  File.swift
//  
//
//  Created by Дмитрий on 21.02.2021.
//

import Vapor
import Fluent
import Vapor

extension UserModel {
    
    struct OutputLogin: Content {
        
        let username: String
        let id: UUID
        let accessToken: String
        let refreshToken: String
        let image: String
        
        init (_ user: UserModel, req: Request) throws {
                        
            self.username = user.username
            self.id = user.id!
            self.accessToken = try user.createToken(req.application, isAccess: true)
            let refreshToken = try user.createToken(req.application, isAccess: false)
            self.refreshToken = refreshToken
            self.image = user.getSourceImage()
            
            _ = RefreshToken.query(on: req.db(.psql))
                .filter(\.$user.$id == user.id!)
                .delete(force: true).map({
                    return RefreshToken(user.id!, token: refreshToken).save(on: req.db(.psql))
                })
        }
    }
    
    struct FullOutput: Content {
        
        let username: String
        var image: String
        let id: UUID
        let createdAt: Date?
        var email: String
        var blogs: [BlogModel.Output]
        init (user: UserModel) {
            self.username = user.username
            self.id = user.id!
            self.createdAt = user.createdAt
            self.email = user.email
            self.blogs = user.blogs.map { BlogModel.Output($0) }
            self.image = user.getSourceImage()
        }
        
    }
    
}
