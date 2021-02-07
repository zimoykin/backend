//
//  File.swift
//  
//
//  Created by Дмитрий on 30.08.2020.
//
import Vapor


struct K {
    
    static var server_address = "0.0.0.0"
    static var external_address = Environment.get("EXRENAL_HOST_ADDRESS")!
    static var server_port = 8000
    
    
    //mail
    static var mailsecret = Environment.get("MAILSECRET")!
    static var mailaddress = Environment.get("MAILADDRESS")!
    static var mailport = Int(Environment.get("MAILPORT")!) ?? 587
    static var mailhost = Environment.get("MAILHOST")!
    
    static func getFullAddress () -> String {
        "http://" + external_address + ":" + String(server_port) + "/"
    }
    
    static func uniq <S: Sequence, T: Hashable>(source: S) -> [T] where S.Iterator.Element == T {
        var buffer = [T]()
        var added = Set<T>()
        for elem in source {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        
        return buffer
    }
    
    static func getnumberOfPages (_ total: Int, _ per: Int) -> Int {
        
        var notFullPage = 0
        
       let rst = (Float(total) / Float(per)) - pow (Float(total) / Float(per), 0)
        
        if rst > 0 {
            notFullPage = 1
        }
        
        return  Int( pow (Float(total) / Float(per), 0)) + notFullPage
        
    }
    
    
    
}
