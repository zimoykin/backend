import Fluent
import Vapor
import JWT

struct UserController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        routes.grouped("api").grouped("users")
            .post("signin", use: create)
        routes.grouped("api").grouped("users")
            .get("confirm", use: confirmed)
        
        let usersLogin = routes.grouped("api").grouped("users")
            .grouped(UserModel.authenticator())
        usersLogin.grouped("login").post(use: login)
        usersLogin.grouped("refresh").post (use: refresh)
        
        let jwtProtected = routes
            .grouped("api")
            .grouped("users")
            .grouped(UserAuthenticatorJWT())
        
        jwtProtected.post("logoff",use: logoff)
        jwtProtected.grouped("avatar").on(.POST, body: .collect(maxSize: 10_000_000), use: uploadAvatar)
        jwtProtected.get("full", use: full)
    }
    
    
    func login (req: Request) throws -> EventLoopFuture<UserModel.OutputLogin> {
        
        guard let user = req.auth.get(UserModel.self)
        else { throw Abort(.unauthorized) }
        
        return try req.eventLoop.makeSucceededFuture ( UserModel.OutputLogin(user, req: req) )
        
    }
    
    func refresh (req: Request) throws -> EventLoopFuture<UserModel.OutputLogin> {
        
        struct RefreshInput: Content {
            var refreshToken: String
        }
        //debugPrint ( req.body.string )
        guard let input: RefreshInput = try? req.content.decode(RefreshInput.self)
        else { throw Abort (.badRequest) }
        
        try req.jwt.verify(input.refreshToken, as: UserPayload.self).exp.verifyNotExpired()
        
        return RefreshToken
            .query(on: req.db)
            .with(\.$user)
            .filter(\.$token == input.refreshToken)
            .first()
            .unwrap(or: Abort (.notFound, reason: "token not found"))
            .flatMapThrowing { user in
                return try UserModel.OutputLogin(user.user, req: req)
            }
        
    }
    
    func logoff (req: Request) throws -> EventLoopFuture <HTTPStatus> {
        
        guard let user = req.auth.get(UserModel.self)
        else { throw Abort(.unauthorized) }
        
        return RefreshToken
            .query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .all().mapEach {
                $0.delete(on: req.db)
            }.transform(to: .ok)
        
    }
    
    func full (req: Request) throws -> EventLoopFuture<UserModel.FullOutput> {
        
        try req.auth.require(UserModel.self)
        
        struct input: Content {
            var user_id: String
        }
        
        guard let data = try? req.query.decode(input.self)
        else { throw Abort (.badRequest) }
        
        guard let id = UUID(uuidString: data.user_id)
        else { throw Abort (.badRequest) }
        //.with(\.$place, { $0.with (\.$post, {$0.with(\.$tags)})})
        return UserModel.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$bids, { $0.with(\.$user)})
            .with(\.$blogs, { $0.with(\.$emotions, { $0.with(\.$blog).with(\.$user)}).with(\.$messages)
                .with(\.$place, {$0.with(\.$country)})
                .with(\.$user)
                .with(\.$bids)
                .with(\.$tags)
            })
            .first()
            .unwrap(or: Abort(.notFound))
            .map {
                UserModel.FullOutput(user: $0)
            }
    }
    
    func uploadAvatar (req: Request) throws -> EventLoopFuture<UserModel.Public> {
        
        struct inputFile: Codable {
            var file: Data
        }
        
        guard let file = try? req.content.decode(inputFile.self)
        else { throw Abort (.badRequest) }
        
        guard let user = req.auth.get(UserModel.self)
        else { throw Abort (.unauthorized) }
        
        let saved = req.eventLoop.makePromise(of: UserModel.Public.self )
        
        saveFile(req: req, user: user, data: file.file) { address in
            if address != nil {
                saved.succeed(user.asPublic())
            } else {
                saved.fail(Abort(.internalServerError))
            }
        }
        
        return saved.futureResult
    }
    
    fileprivate func saveFile (req: Request, user: UserModel, data: Data, completionHandler: @escaping (String?) -> Void ) {
        
        let path = req.application.directory.publicDirectory + "images/avatars/\(user.id!).jpg"
        try? FileManager.default.removeItem(atPath: path)
        
        if FileManager.default.createFile(atPath: path, contents: data, attributes: nil) {
            debugPrint("saved file\n\t \(path)")
            completionHandler ( user.getSourceImage() )
            
        } else {
            debugPrint ("error")
            completionHandler(nil)
        }
    }
    
    fileprivate func create(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        
        guard let data = req.body.data,
              let userSignup = try? JSONDecoder().decode(UserSignup.self, from: data)
        else { throw Abort (.badRequest) }
        
        guard let user = try? UserModel.create(from: userSignup)
        else { throw Abort (.badRequest) }
        
        return user.save(on: req.db).map({
            MailManager.send(req.application, name: user.username, to: user.email,
                             subject: "confirm your account", text: "confirm your account here \n \(K.external_address):\(K.server_port)/api/users/confirm?key=\(user.id!.uuidString)")
        }).transform(to: .ok)

    }
    
    fileprivate func confirmed ( req: Request ) throws -> EventLoopFuture<View> {
        
        struct Input: Codable {
            var key: String
        }
        
        guard
            let data = try? req.query.decode(Input.self),
            let id = UUID(uuidString: data.key)
        else { throw Abort (.badRequest) }
        
        return UserModel.query(on: req.db)
            .filter(\.$id==id)
            .filter(\.$confirmed==false)
            .first()
            .unwrap(or: Abort(.unauthorized))
            .flatMap({
                $0.confirmed = true
                return $0.update(on: req.db).flatMap({
                    return req.view.render("ok")
                })
            })
        
    }
    
}
