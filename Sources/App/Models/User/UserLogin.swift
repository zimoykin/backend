//
//  File.swift
//  
//
//  Created by Дмитрий on 21.02.2021.
//

import Vapor

struct UserLogin: Content {
  let login: String
  let password: String
}
