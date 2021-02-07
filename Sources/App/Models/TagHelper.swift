//
//  File.swift
//  
//
//  Created by Дмитрий on 15.09.2020.
//

import Foundation
import Vapor


extension String {
    func asTag () -> String {
        self.replacingOccurrences(of: " ", with: "").lowercased()
    }
    
    func getShortDescription () -> String {
         var shortText = ""
         
         let charset = CharacterSet(charactersIn: ".?!")
         let arr = self.components(separatedBy: charset)
        
         if arr.count == 0 || arr.count == 1  {
             return description
         }
         
         var shortCount: Int = arr.count / 3
         
         if shortCount < 1 {
             shortCount = 1
         }
         
         if shortCount > 4 {
             shortCount = 4
         }
         
         for i in 0...shortCount {
             shortText += arr[i]
         }
         
         return shortText + "..."
    }
}


