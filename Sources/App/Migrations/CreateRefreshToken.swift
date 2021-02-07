import Fluent

struct CreateToken: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(RefreshToken.schema)
            .id()
            .field("token", .string, .required)
            .unique(on: "token")
            .field("created_at", .datetime)
            .field("user_id", .uuid, .references(UserModel.schema, .id))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(RefreshToken.schema).delete()
    }
}
