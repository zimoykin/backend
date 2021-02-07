import Vapor
import Fluent


struct EmotionController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let api = routes.grouped("api").grouped("emotions").grouped(UserAuthenticatorJWT())
        api.post( use: create )
        api.delete( use: delete )
        api.post("set", use: setEmotion )
        api.get( use: index )
        
    }
    
    func index ( req: Request ) throws -> EventLoopFuture<[EmotionsModel.Output]> {
        
        struct input: Content {
            var blogid: String
        }
        
        guard let data = try? req.query.decode(input.self),
              let blogid = UUID (uuidString: data.blogid)
        else { throw Abort (.badRequest) }
        
        return EmotionsModel.query(on: req.db)
            .filter(\.$blog.$id == blogid)
            .with(\.$user).with(\.$blog)
            .all().mapEach {
                EmotionsModel.Output(params: $0)
            }
        
    }
    
    public func getBlogScore (blogid: UUID, from req: Request) -> EventLoopFuture<HTTPStatus> {
        
        return BlogModel.query(on: req.db)
            .filter(\.$id == blogid)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { blog -> EventLoopFuture<HTTPStatus> in
                var blogRanking = 0
                return blog.$emotions.get(on: req.db).mapEachCompact {
                    $0.emotion == .like ? 2 : $0.emotion == .dislike ? 1 : 0
                }.mapEach{
                    blogRanking += $0
                }.flatMap { _ -> EventLoopFuture<HTTPStatus> in
                    blog.ranking = blogRanking
                    return blog.save(on: req.db).transform(to: .ok)
                }
            }
        
    }
    func delete (req: Request) throws -> EventLoopFuture<HTTPStatus> {
        
        guard let user = req.auth.get(UserModel.self)
        else { throw Abort(.unauthorized) }
        
        struct input: Content {
            var blogid: String
            var emotion: EmotionsType
        }
        
        guard let data = try? req.query.decode(input.self),
              let blogid = UUID (uuidString: data.blogid)
        else { throw Abort (.badRequest) }
        
        return EmotionsModel.query(on: req.db)
            .filter(\.$blog.$id == blogid)
            .filter(\.$user.$id==user.id!)
            .all()
            .map { emotions -> HTTPStatus in
                if emotions.count == 0 {
                    return .notFound
                } else {
                    let hadThis = emotions.filter { $0.emotion == data.emotion }.count > 0
                    _ = emotions.map { $0.delete(on: req.db) }
                    return hadThis ? .found : .ok
                }
            }.map { status in
                _ = self.getBlogScore(blogid: blogid, from: req)
                return status
            }
    }
    
    func create (req: Request) throws -> EventLoopFuture<EmotionsModel.Output> {
        
        guard let user = req.auth.get(UserModel.self)
        else { throw Abort(.unauthorized) }
        
        struct input: Content {
            var blogid: String
            var emotion: EmotionsType
        }
        
        guard let data = try? req.query.decode(input.self),
              let blogid = UUID (uuidString: data.blogid)
        else {
            throw Abort (.badRequest)
        }
        
        let emotion = EmotionsModel(emotion: data.emotion, user: user, blogId: blogid)
        
        return emotion.save(on: req.db).map {
            _ = self.getBlogScore(blogid: blogid, from: req)
        }.map {
            return EmotionsModel.Output(blog_id: blogid, user: user, emotion: emotion)
        }
        
        
    }
    
    func setEmotion (req: Request) throws -> EventLoopFuture<[EmotionsModel.Output]> {
        
        try req.auth.require(UserModel.self)
        
        let response = req.eventLoop.makePromise(of: [EmotionsModel.Output].self)
        
        _ = try self.delete(req: req).flatMapThrowing {
            switch $0 {
            case .notFound:
                _ = try self.create(req: req).flatMapThrowing { _ in
                    _ = try self.index(req: req).map {
                        response.succeed($0)
                    }
                }
            case .found:
                _ = try self.index(req: req).map {
                    response.succeed($0)
                }
            default:
                _ = try self.create(req: req).flatMapThrowing { _ in
                    _ = try self.index(req: req).map {
                        response.succeed($0)
                    }
                }
            }
        }.whenFailure {_ in
            response.fail(Abort (.badRequest))
        }
        return response.futureResult
    }
    
}
