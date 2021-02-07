import Fluent
import Vapor

final class Place: Model, Content {
    static let schema = "places"
    
    struct Output: Content {
        var id: UUID?
        var title: String
        var description: String
        var latitude: Double
        var longitude: Double
        var country: Country.Output
        init (params: Place) {
            self.id = params.id
            self.title = params.title
            self.description = params.description
            self.latitude = params.latitude
            self.longitude = params.longitude
            self.country = params.country.output()
        }
    }
    
    struct InputData: Content {
        var title: String
        var description: String
        var countryId: UUID
        var latitude: Double
        var longitude: Double
        
        func convert() -> Place {
            Place(title: self.title,
                  description: self.description,
                  latitude: self.latitude,
                  longitude: self.latitude,
                  country_id: self.countryId
            )
        }
    }

    
    func output () -> Place.Output {
        Output(params: self)
    }
    
    struct FullOutput: Content {
        var id: UUID?
        var title: String
        var country: Country
        var latitude: Double
        var longitude: Double
        var blogs: [BlogModel.Output]
        init (params: Place) {
            self.id = params.id
            self.title = params.title
            self.country = params.country
            self.latitude = params.latitude
            self.longitude = params.longitude
            self.blogs = params.blogs.map { BlogModel.Output($0) }
        }
    }
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "latitude")
    var latitude: Double
    
    @Field(key: "longitude")
    var longitude: Double
    
    @Parent(key: "country_id")
    var country: Country

    @Children (for: \.$place) var blogs: [BlogModel]

    init() { }

    init(id: UUID? = nil,
         title: String,
         description: String,
         latitude: Double,
         longitude: Double,
         country_id: UUID) {
        self.id = id
        self.title = title
        self.description = description
        self.$country.id = country_id
        self.latitude = latitude
        self.longitude = longitude
    }
}
