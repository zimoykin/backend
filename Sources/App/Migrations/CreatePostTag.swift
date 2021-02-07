import Fluent

struct CreatePostTag: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(BlogTag.schema)
            .id()
            .field("blog_id", .uuid, .references(BlogModel.schema, .id, onDelete: .cascade))
            .field("tag_id", .uuid,  .references(Tag.schema, .id, onDelete: .cascade))
            .unique(on: "blog_id", "tag_id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(BlogTag.schema).delete()
    }
}
