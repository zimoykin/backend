//
//  File.swift
//  
//
//  Created by Дмитрий on 21.02.2021.
//

import Vapor

extension UserModel {
    
    struct Public: Content {
        let username: String
        let id: UUID
        let createdAt: Date?
        let updatedAt: Date?
        var email: String
        let image: String
    }
    
}
