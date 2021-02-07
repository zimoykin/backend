import Fluent

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(UserModel.schema)
            .id()
            .field("username",       .string, .required)
            .unique(on: "username")
            .field("password_hash",  .string, .required)
            .field("email",          .string, .required)
            .field("created_at",     .datetime)
            .field("updated_at",     .datetime)
            .create().flatMap {
                try! UserModel.create(from: UserSignup(username: "admin", email: "admin@goverment.com", password: "@dmin"))
                    .save(on: database)
            }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(UserModel.schema).delete()
    }
}
