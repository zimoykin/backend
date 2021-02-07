//
//  File.swift
//  
//
//  Created by Дмитрий on 08.01.2021.
//

import Vapor

public enum EmotionsType: String, Codable, CaseIterable  {
    case like
    case dislike
    case report
}
