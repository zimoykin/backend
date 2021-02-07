import Fluent

struct CreateBid: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(BidModel.schema)
            .id()
            .field( "bid",        .int, .required )
            .field( "user_id",    .uuid, .references( UserModel.schemaOrAlias, .id, onDelete: .restrict) )
            .field( "blog_id",    .uuid, .references( BlogModel.schema, .id, onDelete: .cascade) )
            .field( "created_at", .datetime  )
            .field( "updated_at", .datetime  )
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(BidModel.schema).delete()
    }
    
}
