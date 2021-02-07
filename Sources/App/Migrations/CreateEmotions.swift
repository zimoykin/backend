import Fluent

struct CreateEmotions: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        
       return database.enum("emotionsType").read().flatMap {
        
        return database.schema(EmotionsModel.schema)
            .id()
            .field("emotion",  $0, .required)
            .field("user_id", .uuid, .references(UserModel.schema, .id, onDelete: .cascade), .required)
            .field("blog_id", .uuid, .references(BlogModel.schema, .id, onDelete: .cascade), .required)
            .unique(on: "emotion", "user_id", "blog_id")
            .field("created_at",     .datetime)
            .field("updated_at",     .datetime)
            .create()
        }
        

    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(EmotionsModel.schema).delete()
    }
}
