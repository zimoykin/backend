import Fluent
import Vapor
import FluentPostgresDriver

struct RawRequestController: RouteCollection {
    
    struct InputData: Codable {
        var query: String
    }
    struct queryConstructor {
        var table: String
        var fields: [String]
        
    }
    //select places.title from places where places.title != 'Japan' LIMIT 3 OFFSET 1
    func boot(routes: RoutesBuilder) throws {
        let query = routes.grouped("raw").grouped(UserAuthenticatorJWT())
        query.get("get", use: index)
    }
    
    func index (req: Request) throws -> EventLoopFuture<String> {
        
        try req.auth.require(UserModel.self)
        return try query(req).flatMapThrowing ({ data -> String in
            
            var jsonString = ""
            
            var result = [[String: Any]]()
            
            _ = try data.map { sqlRow in
                var part = [String: Any]()
                _ = try sqlRow.allColumns.map({ column in
                    part[column] = try sqlRow.decode(column: column, as: String.self)
                })
                result.append(part)
            }
            let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
            jsonString.append( String(data: jsonData, encoding: .utf8)! )
            
            return jsonString
        })
    }
    
    func query (_ req: Request) throws -> EventLoopFuture<[SQLRow]> {
        
        guard let database = req.db as? SQLDatabase
        else { throw Abort(.internalServerError) }
        
        guard let textQuery = try? JSONDecoder().decode(InputData.self, from: req.body.data!)
        else { throw Abort(.badRequest) }
        
        let request = database
            .raw(SQLQueryString(textQuery.query))
        return request.all()
        
    }
    
}
