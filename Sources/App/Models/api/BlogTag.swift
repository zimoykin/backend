import Fluent
import Vapor


final class BlogTag: Model {
    static let schema = "post+tag"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "blog_id")
    var blog: BlogModel

    @Parent(key: "tag_id")
    var tag: Tag

    init() { }

    init(id: UUID? = nil, blog: BlogModel, tag: Tag) throws {
        self.id = id
        self.$blog.id = try blog.requireID()
        self.$tag.id = try tag.requireID()
    }
}
