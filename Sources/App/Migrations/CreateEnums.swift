import Fluent

struct CreateEnums: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        
        let enums = database.enum("emotionsType")
        _ = EmotionsType.allCases.compactMap { enums.case($0.rawValue) }
        
        return enums.create().transform(to: () )
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.enum("emotionsType").delete()
    }
}
