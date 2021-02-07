import Fluent
import Vapor


func routes(_ app: Application) throws {
    
    app.get { req in
        req.redirect(to: "blogs")
    }

    app.get("routes") { req in
        return app.routes.all.map { $0.description }
    }
    
    //api
    try app.register(collection: TodoController())
    try app.register(collection: BlogController())
    try app.register(collection: CountryCollection())
    try app.register(collection: PlaceController())
    try app.register(collection: UserController())
    try app.register(collection: SearchApiController())
    try app.register(collection: EmotionController())
    try app.register(collection: SocketController())
    
    //web
    try app.register(collection: PostViewController())
    try app.register(collection: SearchViewController())
    try app.register(collection: PlaceViewController())
    try app.register(collection: CountryViewController())
    try app.register(collection: UserViewController())
    
    let protected = app.grouped(UserSessionAuthenticator())
    
    try protected.register(collection: BidController())
}
