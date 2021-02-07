import Fluent
import Vapor

struct SearchViewController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let searchRoute = routes
            .grouped("search")
            .grouped(UserSessionAuthenticator())
        searchRoute.get("tag", ":tag", use: SearchView)
        searchRoute.get("location", ":location", use: SearchLocation )
        
    }
    
    private func SearchLocation (_ req: Request) throws -> EventLoopFuture<View> {
        
        var username = req.auth.get(UserModel.self)?.username
        if username == nil {
            username = "login"
        }
        
        let ava = req.auth.get(UserModel.self)?.getSourceImage()
        
        let location = req.parameters.get("location")

        var articles = [Article]()
        
        guard location != nil else {
            throw Abort (.notFound)
        }
        
        let countrySearch = Country.query(on: req.db)
            .filter(\.$title, .equal, location!.lowercased())
            .with(\.$place, { $0.with (\.$blogs, {$0.with(\.$tags)})})
            .sort(\.$title)
            .first()
        let placeSearch = Place.query(on: req.db)
            .filter(\.$title, .equal, location!.lowercased())
            .with(\.$blogs, { $0.with (\.$tags)})
            .with(\.$country)
            .sort(\.$title)
            .first()
        
        return countrySearch.and(placeSearch).flatMap { country, place in
            
            if let countryf = country {

                for i in countryf.place {
                    for blog in i.blogs {
                        articles.append (
                            Article(title: blog.title,
                                    id: blog.id!,
                                    url_image: K.getFullAddress() + "images/post/" + blog.image,
                                    description: blog.description.getShortDescription(),
                                    Tags: blog.tags.map { $0.title },
                                    Locations: [countryf.title, i.title]) )
                        
                    }
                }
            }
            
            if let placef = place {
                
                for blog in placef.blogs {
                    articles.append (
                        Article(title: blog.title,
                                id: blog.id!,
                                url_image: K.getFullAddress() + "images/post/" + blog.image,
                                description: blog.description.getShortDescription(),
                                Tags: blog.tags.map { $0.title },
                                Locations: [placef.title, placef.country.title] ) )
                }
                
            }
            
            let context = Context ( index: Index("Search"),
                                    content: articles,
                                    footer: Footer(),
                                    username: username!.uppercased(),
                                    image_src: ava ?? "not",
                                    bidOwner: "")
            return req.view.render("page", context)
            
        }
        
    } //SearchViewController
    
    func SearchView (_ req: Request) throws -> EventLoopFuture<View> {
        
        var username = req.auth.get(UserModel.self)?.username
        if username == nil {
            username = "login"
        }
        
        let ava = req.auth.get(UserModel.self)?.getSourceImage()
        
        let tags = req.parameters.get("tag")
        
        guard let tagTitle = tags else {
            throw Abort(.badGateway)
        }
        var articles = [Article]()
        
        return Tag.query(on: req.db)
            .filter(\.$title, .equal, tagTitle.asTag())
            .with(\.$blogs, {
                $0.with(\.$tags)
                $0.with(\.$place, {$0.with(\.$country)})})
            .first()
            .flatMap { tag in
                
                if let tag = tag {
                    for post in tag.blogs {
                        
                    articles.append (
                                Article(title: post.title,
                                        id: post.id!,
                                        url_image: K.getFullAddress() + "images/post/" + post.image,
                                        description: post.description.getShortDescription(),
                                        Tags: post.tags.map { $0.title },
                                        Locations: [post.place.country.title, post.place.title]
                                    
                                )
                            )
                        }
                    }
                
                    let context = Context(
                        index: Index("Search"),
                        content: articles,
                        footer: Footer(),
                        username: username!.uppercased(),
                        image_src: ava ?? "not",
                        bidOwner: ""
                        )
                    return req.view.render("page", context)
                
                }
        
    }
    
    
    
    
}
