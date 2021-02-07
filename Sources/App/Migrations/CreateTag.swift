import Fluent

struct CreateTag: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Tag.schema)
            .id()
            .field("title", .string, .required)
            .unique(on: "title")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Tag.schema).delete()
    }
}
