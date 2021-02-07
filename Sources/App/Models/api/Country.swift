import Fluent
import Vapor

final class Country: Model, Content {
    static let schema = "countries"
    
    struct Output: Content {
        var id: UUID?
        var title: String
        var description: String
        init (params: Country) {
            self.id = params.id
            self.title = params.title
            self.description = params.description
        }
    }
    
    func output () -> Output {
        Output(params: self)
    }
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String
    
    @Field(key: "description")
    var description: String

    @Children (for: \.$country) var place: [Place]

    init() { }

    init(id: UUID? = nil, title: String, description: String) {
        self.id = id
        self.title = title
        self.description = description
    }
}
