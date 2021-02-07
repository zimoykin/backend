import Fluent
import Vapor

final class Tag: Model, Content {
    static let schema = "tags"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String
    
    @Siblings(through: BlogTag.self, from: \.$tag, to: \.$blog)
    public var blogs: [BlogModel]

    init() { }

    init(id: UUID? = nil, title: String) {
        self.id = id
        self.title = title
    }
}

extension Tag: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("title", as: String.self, is: .count(2...15))
    }
}
