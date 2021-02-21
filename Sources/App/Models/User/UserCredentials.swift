//
//  File.swift
//  
//
//  Created by Дмитрий on 21.02.2021.
//

import Vapor
import Fluent

struct UserCredentials: Content, Validatable{
    
    let username: String
    let email: String
    let password: String
    
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(5...))
        validations.add("email", as: String.self, is: .email)
    }
    
}

