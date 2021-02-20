import Fluent

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(UserModel.schema)
            .id()
            .field("username",       .string, .required)
            .unique(on: "username")
            .field("password_hash",  .string, .required)
            .field("email",          .string, .required)
            .field("confirmed",      .bool)
            .field("created_at",     .datetime)
            .field("updated_at",     .datetime)
            .create().flatMap {
                let admin = try! UserModel.create(from: UserSignup(username: "admin", email: "admin@goverment.com", password: "@dmin"))
                admin.confirmed = true
                return admin.save(on: database)
            }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(UserModel.schema).delete()
    }
}


struct CreateUserActivity: Migration {
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(UserActivity.schema).delete()
    }
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(UserActivity.schema)
            .id()
            .field("user_id", .uuid, .required)
            .field("type", .string, .required)
            .field("created_at", .datetime)
            .field("ip_address", .string)
            .create()
    }
    
}
