
import Vapor
import Fluent

struct PlaceController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let api_path = routes.grouped("api")
            .grouped("places")
            .grouped(UserAuthenticatorJWT())
        api_path.get(use: index)
        api_path.get("search", use: search)
        api_path.post(use: create)
        
        api_path.get("full", use: full)
    }
    
    
    func index (_ req: Request) throws -> EventLoopFuture<[Place.Output]> {
        try req.auth.require(UserModel.self)
        return Place.query(on: req.db).with(\.$country).sort(\.$title).all().mapEach { $0.output() }
    }
    
    func full (_ req: Request)  throws -> EventLoopFuture<Place.FullOutput> {
        
        try req.auth.require(UserModel.self)
        
        struct input:Content {
            var placeid: String
        }
        
        guard let data = try? req.query.decode(input.self)
        else { throw Abort (.badRequest) }
        
        guard let id = UUID(uuidString: data.placeid)
        else { throw Abort (.badRequest) }
        
        return Place.query(on: req.db)
            .filter(\.$id==id)
            .with(\.$blogs, {$0.with(\.$tags).with(\.$user).with(\.$emotions, { $0.with(\.$blog).with(\.$user)}).with(\.$messages)
                    .with(\.$bids).with(\.$place, {$0.with(\.$country)})})
            .with(\.$country)
            .first()
            .unwrap(or: Abort(.notFound))
            .map {
                Place.FullOutput(params: $0)
            }
        
    }
    
    func create (_ req: Request) throws -> EventLoopFuture<Place> {
        
        try req.auth.require(UserModel.self)
        
        guard let data = try? JSONDecoder().decode(Place.InputData.self, from: req.body.data!)
        else {
            throw Abort (.badRequest)
        }

        let place = data.convert()
        return place.save(on: req.db).map { place }
    }
    
    func search (_ req: Request) throws -> EventLoopFuture<[Place.Output]> {
        
        try req.auth.require(UserModel.self)
        
        struct inputData: Content {
            var field: String
            var value: String
        }
        
        guard var data = try? req.query.decode(inputData.self)
        else { throw Abort (.badRequest) }
        
        if data.field == "country_id" {
            guard let country_id = UUID(uuidString: data.value)
            else { throw Abort(.badRequest) }
            return Place.query(on: req.db).with(\.$country).filter(\.$country.$id == country_id).sort(\.$title).all().mapEach { $0.output() }
        } else {
            data.value = "%" + data.value + "%"
            return Place.query(on: req.db).with(\.$country)
                .filter(.custom("LOWER(\(data.field)) LIKE LOWER(\("'" + data.value + "'"))"))
                .sort(\.$title)
                .all().mapEach({$0.output()})
        }
        
    }
    
}
