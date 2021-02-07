import Foundation
import Vapor

struct Index: Encodable {
    var title: String
    var menu: Menu
    var description: String
    
    init (_ page: String) {
        
        self.title = "Travel <br> bids"
        self.menu = Menu(current_page: page.lowercased())
        self.description = "something this in future"
        
    }
}

struct Location: Encodable {
    var title: String
    var id: UUID
}

struct Menu: Codable {
    var current_page: String
    var menuButton = ["Post", "New", "Country", "Place", "YourBids", "Help"].map { $0.lowercased() }
}

struct Context: Encodable {
    var index:       Index
    var content:     [Article]
    var footer:      Footer
    var username:    String
    var image_src:   String
    var lastBids:    Int?
    var bidOwner:    String
}    

struct Footer: Encodable {
    var author: String  = ""
    var email: String   = ""
}
    
struct Article: Encodable {
    
    var title:          String
    var id:             UUID
    var url_image:      String
    var description:    String
    var Tags:           [String]
    var Locations:      [String]

}


//MARK: - Country Place
struct CountryPlaceContent: Encodable {
    var title: String
    var index: Index
    var description: String
    var countries: [Country]
    var places: [Place]
    var footer: Footer
    var pages: [Int]
    var username: String
}

struct CountryContent: Encodable {
    var index: Index
    var id: String
    var title: String
    var description: String
}

struct PlaceContent: Encodable {
    
    var index: Index
    var id: String
    var title: String
    var description: String
    var posts: Int
    var country: Country?
    var countries: [Country]?
    
}
