import Fluent
import Vapor

struct CountryViewController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let countryRoute = routes
            .grouped("country")
            .grouped(UserSessionAuthenticator())
        countryRoute.get(use: index)
        countryRoute.get(":countryid", use: show)
        countryRoute.post(":countryid", use: update_country)
        countryRoute.get("new", use: create)
        countryRoute.post("new", use: create_post)
       
    }
    
    
    private func index ( _ req: Request) throws -> EventLoopFuture<View> {
        
        var username = req.auth.get(UserModel.self)?.username
        if username == nil {
            username = "login"
        }
        
        return Country.query(on: req.db)
            .sort(\.$title, .ascending)
            .paginate(for: req)
            .flatMap({
                req.view.render("country_place", CountryPlaceContent(
                    title: "Countries",
                    index: Index("Countries"),
                    description: "",
                    countries: $0.items,
                    places: [Place](),
                    footer: Footer(),
                    pages: K.getnumberOfPages ( $0.metadata.total, $0.metadata.per).toArray(),
                    username: username!.uppercased()))
            
        })
        
    }
    
    private func show ( _ req: Request) throws -> EventLoopFuture<View>{
        
        let id_string = req.parameters.get("countryid")
        
        guard let id = UUID(uuidString: id_string!) else {
            throw Abort(.badRequest)
        }
        
        return Country.query(on: req.db)
            .filter(\.$id, .equal, id)
            .with(\.$place)
            .first().map { country in
                CountryContent(index: Index ("Countries"),
                               id: id.uuidString,
                               title: country?.title ?? "",
                               description: country?.description ?? "")
        }.flatMap {
            return req.view.render("form/country", $0)
        }
        
        
    }
    
    private func create ( _ req: Request) throws -> EventLoopFuture<View> {
    
        return req.view.render("form/country",
                               CountryContent(
                                index: Index ("Countries"), id: "",
                                title: "",
                                description: "")
                    )
            
        
    }
    
    private func create_post ( _ req: Request) throws -> EventLoopFuture<Response> {
        
        struct CountryContent: Decodable {
            var title: String
            var description: String
        }
        
        let decodedData = try? req.content.decode(CountryContent.self)
        
        guard let data = decodedData else {
            throw Abort(.badRequest)
        }
        
        return Country(title: data.title.lowercased(),
                       description: data.description.lowercased())
            .save(on: req.db)
            .map {
                req.redirect(to: "/country")
            }
        
    }
    
    private func update_country ( _ req: Request) throws -> EventLoopFuture<Response> {
       
        struct CountryContent: Decodable {
            var title: String
            var description: String
        }
        
        let decodedData = try? req.content.decode(CountryContent.self)
        
        let idString = req.parameters.get("countryid")
        
        guard let data = decodedData else {
            throw Abort(.badRequest)
        }
        guard let id = UUID(uuidString: idString!) else {
            throw Abort(.badRequest)
        }
        
        return Country.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .map {
                $0.title = data.title
                $0.description = data.description
                _ = $0.update(on: req.db)
            }.map {
                req.redirect(to: "/Country")
            }
    }
    
    
 }
