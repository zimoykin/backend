import Fluent

struct CreatePost: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(BlogModel.schema)
            .id()
            .field("title",          .string,   .required)
            .field("description",    .string,   .required)
            .field("is_active",      .bool,     .required)
            .field("ranking",        .int,      .required)
            .field("image",          .string,   .required)
            .field("place_id",       .uuid,     .references(Place.schema, .id), .required )
            .field("created_at",     .datetime  )
            .field("updated_at",     .datetime  )
            .field("user_id",       .uuid, .references(UserModel.schemaOrAlias, .id, onDelete: .restrict), .required )
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(BlogModel.schema).delete()
    }
}
