import Fluent

struct CreateMessages: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        
        return database.schema(MessageModel.schema)
            .id()
            .field("message",       .string, .required)
            .field("user_id",       .uuid, .references(UserModel.schema, .id, onDelete: .cascade), .required)
            .field("blog_id",       .uuid, .references(BlogModel.schema, .id, onDelete: .cascade))
            .field("to_user_id",    .uuid, .references(BlogModel.schema, .id, onDelete: .cascade))
            .field("created_at",    .datetime)
            .field("updated_at",    .datetime)
            .create()

    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(MessageModel.schema).delete()
    }
}
