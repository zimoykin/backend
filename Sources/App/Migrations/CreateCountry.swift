import Fluent

struct CreateCountry: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Country.schema)
            .id()
            .field("title",         .string, .required)
            .unique(on: "title")
            .field("description",   .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Country.schema).delete()
    }
}
