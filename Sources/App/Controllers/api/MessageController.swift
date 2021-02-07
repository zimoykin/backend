import Vapor
import Fluent


struct MessageController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let api = routes.grouped("api").grouped("messages").grouped(UserAuthenticatorJWT())
        api.post("blog", use: create )
        api.post("direct", use: direct )
        api.delete(":messageid", use: delete )
        api.get( use: index )
        
    }
    
    
    func index ( req: Request ) throws -> EventLoopFuture<[MessageModel.Output]> {
        
        struct input: Content {
            var itemid: String
        }
        
        guard let data = try? req.query.decode(input.self),
              let itemid = UUID (uuidString: data.itemid)
        else { throw Abort (.badRequest) }
        
        return MessageModel.query(on: req.db)
            .group(.or) { or in
                or.filter(\.$blog.$id == itemid)
                or.filter(\.$toUser.$id == itemid)
            }
            .with(\.$user)
            .with(\.$blog)
            .with(\.$toUser)
            .all().mapEach {
                MessageModel.Output(params: $0)
            }
        
    }
    
    func create (req: Request) throws -> EventLoopFuture<MessageModel.Output> {
        
        guard let user = req.auth.get(UserModel.self)
        else { throw Abort(.unauthorized) }
        
        struct input: Content {
            var blogid: String
            var message: String
        }
        
        guard let data = try? req.query.decode(input.self),
              let blogid = UUID (uuidString: data.blogid)
        else {
            throw Abort (.badRequest)
        }
        
        let message = MessageModel(message: data.message, userid: user.id!, blogid: blogid)
        
        return message.save(on: req.db).map {
            _ = EmotionController().getBlogScore(blogid: blogid, from: req)
        }.map {
            return MessageModel.Output(params: message)
        }
    
    }

    func direct (req: Request) throws -> EventLoopFuture<MessageModel.Output> {
        
        guard let user = req.auth.get(UserModel.self)
        else { throw Abort(.unauthorized) }
        
        struct input: Content {
            var userid: String
            var message: String
        }
        
        guard let data = try? req.query.decode(input.self),
              let userid = UUID (uuidString: data.userid)
        else {
            throw Abort (.badRequest)
        }
        
        let message = MessageModel(message: data.message, userid: user.id!, touserid: userid)
        
        return message.save(on: req.db).map {
            //_ = EmotionController().getBlogScore(blogid: blogid, from: req)
            _ = req.application.sockets.clients.filter({$0.user.id == userid}).map({
                $0.socket.send(message.message)
            })
        }.map {
            return MessageModel.Output(params: message)
        }
    
    }
    
    
    private func delete (req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return MessageModel.find(req.parameters.get("messageid"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
    
}
