import Fluent
import Vapor

struct PlaceViewController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let placeRoute = routes
            .grouped("place")
            .grouped(UserSessionAuthenticator())
        placeRoute.get(use: index)
        placeRoute.get(":placeid", use: show)
        placeRoute.post(":placeid", use: update)
        placeRoute.get("new",   use: createView)
        
    }
    
    private func index ( _ req: Request) throws -> EventLoopFuture<View> {
        
        var username = req.auth.get(UserModel.self)?.username
        if username == nil {
            username = "login"
        }
        
        return Place.query(on: req.db)
            .sort(\.$title, .ascending)
            .paginate(for: req)
            .flatMap({
                 req.view.render("country_place",
                                   CountryPlaceContent(
                                    title: "Places",
                                    index: Index("Places"),
                                    description: "",
                                    countries: [Country](),
                                    places: $0.items,
                                    footer: Footer(),
                                    pages: K.getnumberOfPages ($0.metadata.total, $0.metadata.per).toArray(),
                                    username: username!.uppercased()
                                    ) )
                
            })
    }
    
    private func show ( _ req: Request) throws -> EventLoopFuture<View>{
        
        var username = req.auth.get(UserModel.self)?.username
        if username == nil {
            username = "login"
        }
        
        let id_string = req.parameters.get("placeid")
        
        guard let id = UUID(uuidString: id_string!) else {
            throw Abort(.badRequest)
        }
        
        return Country.query(on: req.db).all().flatMap { countries in
            
            return Place.query(on: req.db)
                .filter(\.$id, .equal, id)
                .with(\.$country)
                .with(\.$blogs)
                .first().map { place in
                    return PlaceContent(index: Index ("places"),
                                 id: id.uuidString,
                                 title: place?.title ?? "",
                                 description: place?.description ?? "",
                                 posts: place?.blogs.count ?? 0,
                                 country: place?.country,
                                 countries: countries
                    )
            }
        }.flatMap {
            req.view.render("form/place", $0)
        }
    }
    
    private func update ( _ req: Request) throws -> EventLoopFuture<Response> {
        
        var username = req.auth.get(UserModel.self)?.username
        if username == nil {
            username = "login"
        }
        
        let idString = req.parameters.get("placeid")
        
        guard let id = UUID(uuidString: idString!) else {
            throw Abort(.badRequest, reason: "bad uuid")
        }
        
        struct PlaceContent: Decodable {
            var title: String
            var description: String
            var countryId: String
        }
        
        let decodedData = try? req.content.decode(PlaceContent.self)
        
        guard let data = decodedData else {
            throw Abort(.badRequest, reason: "can't read data")
        }
        
        return Place.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .map {
                $0.title = data.title
                $0.description = data.description
                $0.$country.id = UUID(uuidString: data.countryId)!
                _ = $0.update(on: req.db)
        }.map {
            req.redirect(to: "/place")
        }
    }
    
    private func createView ( _ req: Request) throws -> EventLoopFuture<View> {
        
        var username = req.auth.get(UserModel.self)?.username
        if username == nil {
            username = "login"
        }
        
        struct placeContext: Encodable {
            var countries: [Country]
            var index: Index = Index.init("place")
        }
        
        return Country.query(on: req.db).all().flatMap { countries in
            return req.view.render("form/place", placeContext(countries: countries))
        }
        
    }
    
}
