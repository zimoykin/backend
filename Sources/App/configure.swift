import Fluent
import FluentPostgresDriver
import FluentMongoDriver
import Vapor
import Leaf
import JWT

// configures your application
fileprivate func migrations(_ app: Application) {
    app.migrations.add(CreateEnums(), to: .psql)
    app.migrations.add(CreateUser(), to: .psql)
    app.migrations.add(CreateTodo(), to: .psql)
    app.migrations.add(CreateCountry(), to: .psql)
    app.migrations.add(CreatePlace(), to: .psql)
    app.migrations.add(CreatePost(), to: .psql)
    app.migrations.add(CreateTag(), to: .psql)
    app.migrations.add(CreatePostTag(), to: .psql)
    app.migrations.add(CreateBid(), to: .psql)
    app.migrations.add(CreateToken(), to: .psql)
    app.migrations.add(CreateEmotions(), to: .psql)
    app.migrations.add(CreateMessages(), to: .psql)
    app.migrations.add(CreateTriggers(), to: .psql)
    app.migrations.add(CreateUserActivity(), to: .mongo)
}

public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(CORSMiddleware(configuration: .default()))
    app.middleware.use(CorrectAddressMiddleware())
    
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST")!,
        username: Environment.get("DATABASE_USERNAME")!,
        password: Environment.get("DATABASE_PASSWORD")!,
        database: Environment.get("DATABASE_NAME")!
    ), as: .psql)
    
    try! app.databases.use(.mongo(
        connectionString: "mongodb://localhost:27017/VAPOR"
    ), as: .mongo)
    
    migrations(app)
    
    app.logger.logLevel = .debug
   
    //try app.autoRevert().wait()
    try app.autoMigrate().wait()
    app.jwt.signers.use(.hs256(key: Environment.get("KEY_JWT")!))
    
    app.views.use(.leaf)
    app.leaf.cache.isEnabled = app.environment.isRelease
    
    app.leaf.tags[YearTag.name] = YearTag()
    app.leaf.tags[DeleteImageTag.name] = DeleteImageTag(app: app)
    app.leaf.tags[EditImageTag.name] = EditImageTag(app: app)

    app.http.server.configuration.hostname = K.server_address
    app.http.server.configuration.port = K.server_port

    app.migrations.add(SessionRecord.migration)
    app.middleware.use(app.sessions.middleware)
    
    // register routes
    try routes(app)

    fileConfigure (app)
    
}


fileprivate func fileConfigure (_ app: Application ) {

    createdirectory (app.directory.publicDirectory + "images")
    createdirectory (app.directory.publicDirectory + "images/blog/")
    createdirectory (app.directory.publicDirectory + "images/system/")
    createdirectory (app.directory.publicDirectory + "images/avatars/")

}

fileprivate func createdirectory (_ pathFolder: String) {
    
        if !FileManager.default.fileExists(atPath: pathFolder) {
            try! FileManager.default.createDirectory(at: URL(fileURLWithPath: pathFolder), withIntermediateDirectories: true)
        } else {
            print("directory exist: "+pathFolder)
        }

}
