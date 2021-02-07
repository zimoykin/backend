
import Vapor
import Fluent

struct CountryCollection: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let api_path = routes.grouped("api")
            .grouped("countries")
            .grouped(UserAuthenticatorJWT())
        api_path.get(use: index)
        api_path.get("list", use: indexSimple)
        api_path.post(use: create)
    }
    
    
    func index (_ req: Request) throws -> EventLoopFuture<[Country]> {
        try req.auth.require(UserModel.self)
        
        return Country.query(on: req.db)
            .with(\.$place, { $0.with(\.$blogs)})
            .all()
    }
    
    func indexSimple (_ req: Request) throws -> EventLoopFuture<[Country]> {
        try req.auth.require(UserModel.self)
        return Country.query(on: req.db)
            .sort(\.$title)
            .all()
    }
    
    
    func create (_ req: Request) throws -> EventLoopFuture<Country> {
        
        try req.auth.require(UserModel.self)
        
        guard let country = try? JSONDecoder().decode(Country.self, from: req.body.data!)
        else {
            throw Abort (.badRequest)
        }
        
        return country.save(on: req.db).map { country }
    }
    
}
