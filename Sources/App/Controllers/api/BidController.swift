import Fluent
import Vapor

struct BidController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let bids = routes.grouped("api").grouped("bids")
        bids.post(":postID", use: create)
 
    }

    func create(req: Request) throws -> EventLoopFuture<Response> {
        
        struct BidInput: Decodable {
            var bid: Int
        }
  
        let userO = req.auth.get(UserModel.self)
        
        guard let user = userO else {
            throw Abort (.unauthorized)
        }
        
        let post_id = req.parameters.get("postID")
        
        guard let blogID = UUID(uuidString: post_id!) else {
            throw Abort (.badRequest)
        }
        
        let bidContent = try? req.content.decode(BidInput.self)
        
        guard let bid: BidInput = bidContent else {
            throw Abort (.badRequest, reason: "input parameter error")
        }
        
        let promise = req.eventLoop.makePromise(of: Response.self)
        
        _ = BlogModel.find(blogID, on: req.db)
            .unwrap(or: Abort (.notFound))
            .map { blog in
                
                BidModel.query(on: req.db)
                    .filter(\.$blog.$id, .equal , blog.id!)
                    .sort(\.$createdAt, .descending)
                    .first()
                    .map {
                        
                        let currentBid = $0?.bid ?? 0
                        
                        if bid.bid > currentBid {
                            _ = blog
                                .$bids
                                .create(BidModel(bid: bid.bid, userID: user.id!, blogID: blog.id!), on: req.db)
                                .map {
                                    promise.succeed(req.redirect(to: "/post/\(blog.id!)"))
                            }
                        }
                        
                        else {
                            promise.fail("current bid greater then your bid!")
                        }

                    }
            }
            
        return promise.futureResult
        
    } //create

}
