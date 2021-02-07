import Fluent
import Vapor
import Foundation

struct UserViewController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let usersSignIn = routes.grouped("signin")
        usersSignIn.get(use: showsignin)
        usersSignIn.post(use: create)
        
        let usersLogIn = routes.grouped("login")
        usersLogIn.post(use: login)
        usersLogIn.get(use: showlogin)
        
        let logout = routes.grouped("logout")
        logout.post(use: logoff)
        
        let bidsRoutes = routes.grouped("yourbids").grouped(UserSessionAuthenticator())
        bidsRoutes.get(use: bidsIndex)
        
    }
    
    fileprivate func showsignin (req: Request) throws -> EventLoopFuture <View> {
        req.view.render("signin")
    }
    
    fileprivate func showlogin (req: Request) throws -> EventLoopFuture <View> {
        req.view.render("login")
    }
    
    fileprivate func index(req: Request) throws -> EventLoopFuture<[UserModel.Public]> {
        return UserModel.query(on: req.db).all().mapEach {
            return $0.asPublic()
        }
    }
    
    ///////////
    fileprivate func login (req: Request) throws -> EventLoopFuture<Response> {
        
        var username = req.auth.get(UserModel.self)?.username
        if username == nil {
            username = "login"
        }
        
        guard let loginData = try? req.content.decode(UserLogin.self) else {
            throw Abort(.badRequest, reason: "Error decode data")
        }
        
        return UserModel.query(on: req.db)
            .group(.or) { query in
                query.filter(\.$email,      .equal, loginData.login )
                query.filter(\.$username,   .equal, loginData.login )
            }
            .first()
            .map({ user in
                
                if user != nil {
                    guard try! user!.verify(password: loginData.password) else {
                        
                        if let address = req.headers["Referer"].first,
                           address != req.url.path && !address.contains("/login") && !address.contains("/signin") {
                            return req.redirect(to: address)
                        } else {
                            return req.redirect(to: "/login")
                        }
                        
                    }
                    req.session.authenticate(user!)
                    
                    if let address = req.headers["Referer"].first,
                       address != req.url.path && !address.contains("/login") && !address.contains("/signin")
                    {
                        return req.redirect(to: address)
                    } else {
                        return req.redirect(to: "/post")
                    }
                    
                    
                } else {
                    return req.redirect(to:"/signin")
                }
            })
        
    }
    
    ///////////
    
    fileprivate func logoff (req: Request) throws -> Response {
        
        req.session.destroy()
        
        if let address = req.headers["Referer"].first,
           address != req.url.path && !address.contains("/login") && !address.contains("/signin") && !address.contains("/logout")
        {
            return req.redirect(to: address)
        } else {
            return req.redirect(to: "/post")
        }
        
    }
    
    fileprivate func create(req: Request) throws -> EventLoopFuture<Response> {
        
        let promise = req.eventLoop.makePromise(of: Response.self)
        try UserSignup.validate(content: req)
        
        let userSignup = try? req.content.decode(UserSignup.self)
        
        if let userSignUpd = userSignup {
            
            let userO = try? UserModel.create(from: userSignUpd)
            
            if let user = userO {
                
                user.save(on: req.db).map {
                    
                    req.auth.login(user)
                    
                    if let address = req.headers["Referer"].first, !address.contains("signin") && !address.contains("login") {
                        promise.succeed( req.redirect(to: address) )
                    } else {
                        promise.succeed( req.redirect(to: "/post") )
                    }
                    
                }.whenFailure(
                    promise.fail(_:)
                )
            }
            
            else {
                promise.fail("bad request")
            }
        }
        else {
            promise.fail("bad request")
        }
        
        return promise.futureResult
    }
    
    //MARK: BIDS
    fileprivate func bidsIndex (req: Request) throws -> EventLoopFuture <View> {
        
        guard req.auth.has(UserModel.self) else {
            req.headers.add(name: "urlPrevius", value: req.url.path)
            return req.view.render("login")
        }
        
        guard let user = req.auth.get(UserModel.self) else {
            throw Abort( .unauthorized )
        }
        
        //
        struct UbidsOutput: Encodable {
            var username: String
            var index = Index("your bids")
            var content: [BidContent]
            var footer = Footer()
            
            struct BidContent: Encodable {
                var post: BlogModel
                var url_image: String
                var tags: [Tag]
                var bid: lastBid
                var lastBidDate: Date
            }
            
            struct lastBid: Encodable {
                var bid: Int
                var isItYours: Bool
            }
        }
        
        return BidModel.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .sort(\.$createdAt, .descending)
            .with(\.$blog)
            .all()
            .map { bid -> [UUID] in
               
                //let sorted = bid.sorted { $0.createdAt! < $1.createdAt!}
                return K.uniq(source: bid.map {$0.blog.id!})
                
            }.flatMap { ids -> EventLoopFuture<[UbidsOutput.BidContent]> in
                
                let promisePost = req.eventLoop.makePromise(of: [UbidsOutput.BidContent].self)
                
                if ids.count > 0 {
                    _ = BlogModel.query(on: req.db)
                        .group(.or)
                        { and in
                                _ = ids.map {
                                   return and.filter(\.$id == $0)
                                }
                            }
                        .with(\.$bids, {$0.with(\.$user)}).with(\.$tags)
                        .sort(\.$createdAt, .descending)
                        .all()
                        .mapEach{ post -> UbidsOutput.BidContent in
                           
                            var lastBid: BidModel?
                            
                            if post.bids.count > 0 {
                                lastBid = post.bids.sorted { $0.createdAt! > $1.createdAt! }[0]
                            }
                            
                            return UbidsOutput.BidContent.init(post: post, url_image: post.getImageAddress(), tags: post.tags, bid: UbidsOutput.lastBid(bid: lastBid?.bid ?? 0, isItYours: lastBid?.user.id! == user.id), lastBidDate: lastBid?.createdAt! ?? Date())
                        }.map {
                            promisePost.succeed($0.sorted { $0.lastBidDate > $1.lastBidDate})
                        }
                } else {
                    let noBids = [UbidsOutput.BidContent]()
                    promisePost.succeed(noBids)
                }
        
                 return promisePost.futureResult
    
             }.flatMap {
                req.view.render("form/yourbids", UbidsOutput(username: user.username, content: $0))
            }
        
        
        
    }
    
}
