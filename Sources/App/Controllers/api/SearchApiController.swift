import Fluent
import Vapor

struct SearchApiController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let searchRoute = routes
            .grouped("api")
            .grouped("search")
            .grouped(UserAuthenticatorJWT())
        
        searchRoute.get("tag", use: searchTag)
        searchRoute.get("blogs", use: searchBlogs)
        searchRoute.get("location", ":location", use: searchLocation )
        
    }
    
    func searchLocation (req: Request) throws -> EventLoopFuture<[BlogModel.Output]> {
       
        try req.auth.require(UserModel.self)
    
        guard let location = req.parameters.get("location")
        else {
            throw Abort (.notFound)
        }
        
        var articles = [BlogModel.Output]()
       
        let countrySearch = Country.query(on: req.db)
            .filter(\.$title, .equal, location.lowercased())
            .with(\.$place, { $0.with (\.$blogs, {$0.with(\.$tags).with(\.$emotions, { $0.with(\.$blog).with(\.$user)}).with(\.$messages)})})
            .sort(\.$title)
            .first()
        let placeSearch = Place.query(on: req.db)
            .filter(\.$title, .equal, location.lowercased())
            .with(\.$blogs, { $0.with (\.$tags).with(\.$emotions, { $0.with(\.$blog).with(\.$user)}).with(\.$messages)})
            .with(\.$country)
            .sort(\.$title)
            .first()
        
        return countrySearch.and(placeSearch).flatMap { country, place in
        
            _ = country.map { country in
                country.place.map { place in
                    place.blogs.map { blog in
                        if articles.filter ({ $0.id! == blog.id! }).count == 0 {
                            articles.append( BlogModel.Output(blog) )
                        }
                    }
                }
            }
           _ = place.map { place in
                place.blogs.map { blog in
                    if articles.filter ({ $0.id! == blog.id! }).count == 0 {
                        articles.append( BlogModel.Output(blog) )
                    }
                }
            }
            
            return req.eventLoop.makeSucceededFuture ( articles )
         
            
        }
    }
    
    func searchTag (_ req: Request) throws -> EventLoopFuture<Page<String>> {
        
        try req.auth.require(UserModel.self)
        
        struct inputData: Content {
            var tag: String
        }
        
        guard let input = try? req.query.decode(inputData.self)
        else { throw Abort(.badRequest) }
       // query.join(Address.self, on: \Address.$id==\Company.$address.$id, method: .left).sort(Address.self,\.$country, order)
     
        return BlogModel.query(on: req.db)
            .join(siblings: \.$tags)
            .filter(Tag.self, \Tag.$title ~~ input.tag)
            .field(\.$id)
            .field(\.$ranking)
            .field(.custom("date_trunc('day', \(BlogModel.schema).created_at)"))
            .sort(.custom("date_trunc('day', \(BlogModel.schema).created_at) DESC"))
            .sort(.custom("\(BlogModel.schema).ranking DESC"))
            .sort(\.$createdAt, .descending)
            .paginate(for: req)
            .map {
                return $0.map { blog in
                    blog.id!.uuidString
                }
             }
            

    }
    
    func searchBlogs ( req: Request) throws -> EventLoopFuture<Page<String>> {
        
        try req.auth.require(UserModel.self)
        
        struct input: Content {
            var value: String
        }
        
        guard let data = try? req.query.decode(input.self)
        else { throw Abort(.badRequest) }
        
        return BlogModel.query(on: req.db)
            .join(Place.self, on: \Place.$id==\BlogModel.$place.$id, method: .left)
            .join(Country.self, on: \Country.$id==\Place.$country.$id, method: .left)
            .join(UserModel.self, on: \UserModel.$id==\BlogModel.$user.$id, method: .left)
            .group(.or) { or in
                or.filter(.custom("LOWER(\(BlogModel.schema).title) LIKE LOWER('%\(data.value)%')"))
                or.filter(.custom("LOWER(\(BlogModel.schema).description) LIKE LOWER('%\(data.value)%')"))
                or.filter(.custom("LOWER(\(Place.schema).title) LIKE LOWER('%\(data.value)%')"))
                or.filter(.custom("LOWER(\(Country.schema).title) LIKE LOWER('%\(data.value)%')"))
                or.filter(.custom("LOWER(\(UserModel.schema).username) LIKE LOWER('%\(data.value)%')"))
                or.filter(.custom("LOWER(\(UserModel.schema).email) LIKE LOWER('%\(data.value)%')"))
            }
            .unique()
            .field(\.$id)
            .field(\.$ranking)
            .field(.custom("date_trunc('day', \(BlogModel.schema).created_at)"))
            .sort(.custom("date_trunc('day', \(BlogModel.schema).created_at) DESC"))
            .sort(.custom("\(BlogModel.schema).ranking DESC"))
            .paginate(for: req).map { page in
                page.map { $0.id!.uuidString }
            }
        
    }

}
