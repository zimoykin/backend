import Fluent
import Vapor

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
                let admin = try! UserModel.create(from: UserCredentials(username: Environment.get("ADMIN_USERNAME")!,
                                                                   email: Environment.get("ADMIN_EMAIL")!,
                                                                   password: Environment.get("ADMIN_PASSWORD")!))
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
