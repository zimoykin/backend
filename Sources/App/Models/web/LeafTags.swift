import Vapor
import Leaf
import Foundation

struct YearTag: LeafTag {
    
    static let name: String = "year"

    func render(_ ctx: LeafContext) throws -> LeafData {
        let value = String ( Calendar.current.component(.year, from: Date()) )
        return .string (value)
    }
}

struct DeleteImageTag: LeafTag {
    
    static let name: String = "delImage"
    let app: Application
    
    func render(_ ctx: LeafContext) throws -> LeafData {
        
        let path = app.directory.workingDirectory + "/public/images/system/clear.png"
        
        if FileManager.default.fileExists(atPath: path) {
             return .string ( K.getFullAddress() + "images/system/clear.png")
        } else {
            return .string("")
        }
    }
}

struct EditImageTag: LeafTag {
    
    static let name: String = "editImage"
    let app: Application
    
    func render(_ ctx: LeafContext) throws -> LeafData {
        
        let path = app.directory.workingDirectory + "/public/images/system/pencil.png"
        
        if FileManager.default.fileExists(atPath: path) {
            return .string ( K.getFullAddress() + "images/system/pencil.png")
        } else {
            return .string("")
        }
    }
}
