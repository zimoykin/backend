import Fluent
import Vapor

struct PostViewController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let protected = routes
            .grouped("post")
            .grouped(UserSessionAuthenticator())
        
        protected.get(use: index)
        protected.get(":postID", use: showPostView)
        protected.get("upd",":postID", use: showPostUpdateView)
        protected.on(.POST, ":postID", body: .collect(maxSize: 10_000_000), use: update)
        protected.get("new", use: showCreateView)
        protected.on(.POST, body: .collect(maxSize: 10_000_000), use: createNew)
        
        protected.post("del", ":postID", use: delPost)
        
    }
    
    
    func index (_ req: Request) -> EventLoopFuture<View> {
        
        let page = "Post"

        
        var username = req.auth.get(UserModel.self)?.username
        if username == nil {
            username = "login"
        }
        let ava = req.auth.get(UserModel.self)?.getSourceImage()
        
        return BlogModel.query(on: req.db)
            .with(\.$place, { $0.with(\.$country)})
            .with(\.$tags)
            .sort(\.$createdAt, .descending)
            .all().mapEach({ (post) -> Article in
                
                return Article(title: post.title,
                               id: post.id!,
                               url_image: post.getImageAddress(),
                               description: post.description.getShortDescription(),
                               Tags: post.tags.map{$0.title},
                               Locations: [post.place.country.title, post.place.title])
            })
            .flatMap {
                let context = Context(index: Index(page),
                                      content: $0,
                                      footer: Footer(),
                                      username: username!.uppercased(),
                                      image_src: ava ?? "not", bidOwner: ""
                                      )
                
                return req.view.render("page", context)
        }
    }
    
    private func showCreateView (_ req: Request) throws -> EventLoopFuture<View> {
       
        guard req.auth.has(UserModel.self) else {
            req.headers.add(name: "urlPrevius", value: req.url.path)
            return req.view.render("login")
        }
        
        var username = req.auth.get(UserModel.self)?.username
        if username == nil {
            username = "login"
        }
        
        struct newPostContext: Encodable {
            var location: [Location]
            var index: Index
            var image_src = K.getFullAddress() + "/images/system/imageSelect.jpg"
            var username: String
        }
        
        
        return Place.query(on: req.db).sort(\.$title).all().mapEach ({ place in
            
            return Location(title: place.title, id: place.id!)
            
        }).flatMap {
            let context = newPostContext(location: $0, index: Index("new"), username: username!.uppercased())
            return req.view.render("form/post", context)
        }
        
    }
    
    private func showPostUpdateView (_ req: Request) throws -> EventLoopFuture<View> {
        
        guard req.auth.has(UserModel.self) else {
            return req.view.render("login")
        }
        let username = req.auth.get(UserModel.self)?.username
        
        struct updPostContext: Encodable {
            var location: [Place]
            var index: Index
            var post: BlogModel
            var tags: String
            var image_src: String
            var username: String
            var authrozed: Bool
        }
        
        guard
            let postIDstring = req.parameters.get("postID"),
            let postId =  UUID(postIDstring)
            else {
                throw Abort(.badRequest, reason: "Bad UUID")
        }
        
        return Place.query(on: req.db)
            .sort(\.$title)
            .all()
            .flatMap { places in
                
                return BlogModel
                    .query(on: req.db)
                    .filter(\.$id, .equal, postId)
                    .with(\.$tags)
                    .with(\.$place)
                    .first().unwrap(or: Abort(.notFound))
                    .map {
                        return updPostContext(location: places,
                                              index: Index.init("update"),
                                              post: $0,
                                              tags: self.forForm($0.tags),
                                              image_src: K.getFullAddress() + "images/post/" + $0.image,
                                              username: username!.uppercased(),
                                              authrozed: true)
                }.flatMap {
                    req.view.render("form/post", $0)
                }
        }
    }
    
    private func createNew (_ req: Request) throws -> EventLoopFuture<Response>  {
        
         guard let user = req.auth.get(UserModel.self) else {
            return req.eventLoop.future().map {
                req.redirect(to: "/login")
            }
        }
        
      
        let decodedData = try req.content.decode(PostData.self)
        let id = UUID()
        let newPost = BlogModel(id: id,
                           title: decodedData.title,
                           description: decodedData.description, user_id: user.id!,
                           image: id.uuidString + ".jpg",
                           place_id: decodedData.placeId)
        newPost.$user.id = user.id!
        
        let path = req.application.directory.workingDirectory + "/public/images/post/\(id.uuidString).jpg"
        
        return newPost.save(on: req.db).map { post in
            try? self.saveFile(path: path, data: decodedData.image!)
           
            let tags = decodedData.tags.components(separatedBy: "#")
            for tag in tags {
                      if tag.replacingOccurrences(of: " ", with: "").count > 0 {
                          
                        let correctTag = tag.asTag()
                        
                        _ = Tag.query(on: req.db).filter(\.$title, .equal, correctTag).first().flatMapThrowing { (tagModel) in
                              if tagModel == nil {
                                  let newTag = Tag(title: correctTag)
                                  _ = newTag.save(on: req.db).map {
                                    _ = newPost.$tags.attach(newTag, on: req.db)
                                  }
                              } else  {
                                   _ = newPost.$tags.attach(tagModel!, on: req.db)
                                }
                              }
                          }
              }

        }.map {
            return req.redirect(to: "/post")
        }
    }
    
    private func update ( _ req: Request) throws -> EventLoopFuture<Response>  {
        
        guard req.auth.has(UserModel.self) else {
            return req.eventLoop.future( req.redirect(to: "/login") )
        }
        
        let decodedData = try req.content.decode(PostData.self)
        
        let idString = req.parameters.get("postID")
        
        guard let id = UUID(uuidString: idString!) else {
            throw Abort(.badRequest, reason: "wrongs id as parameters")
        }
        
        let path = req.application.directory.publicDirectory + "/images/post/\(id.uuidString).jpg"
        
        return BlogModel.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap {
                $0.title = decodedData.title
                $0.description = decodedData.description
                $0.$place.id = decodedData.placeId
                return $0.update(on: req.db).map {
                    if !decodedData.image!.isEmpty {
                        try? self.saveFile(path: path, data: decodedData.image!)
                    }
                }
        }.map {
            return req.redirect(to: "/")
        }
        
        
    }

    func delPost (_ req: Request) throws -> EventLoopFuture<Response> {
        
       guard req.auth.has(UserModel.self) else {
            return req.eventLoop.future( req.redirect(to: "/login") )
        }
        
      return  BlogModel.find(req.parameters.get("postID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap {
                $0.delete(force: true, on: req.db)
        }.map {
            return req.redirect(to: "/post")
        }
        
        
    }
    
    func showPostView (_ req: Request) throws -> EventLoopFuture<View> {

        guard req.auth.has(UserModel.self) else {
            req.headers.add(name: "urlPrevius", value: req.url.path)
            return req.view.render("login")
        }
        
        var username = req.auth.get(UserModel.self)?.username
        if username == nil {
            username = "login"
        }
        
        let page = "blog"
        
        let ava = req.auth.get(UserModel.self)?.getSourceImage()
        
        guard
            let postIDstring = req.parameters.get("postID"),
            let postId =  UUID(postIDstring)
         else {
            throw Abort(.badRequest, reason: "Bad UUID")
        }
        
        return BlogModel.query(on: req.db)
            .filter(\.$id, .equal, postId)
            .with(\.$place, { $0.with(\.$country)})
            .with(\.$tags)
            .with(\.$bids, {$0.with(\.$user)})
                .sort(\.$createdAt, .descending)
            .first()
            .unwrap(or: Abort(.notFound, reason: "not found"))
            .flatMap{ post in
                var isYourBids = ""
                if post.bids.count > 0  {
                    if post.bids[post.bids.count-1].user.id == req.auth.get(UserModel.self)?.id {
                        isYourBids = "this is your bids!"
                    } else {
                        isYourBids = "this isn't your bids!"
                    }
                    
                }
                
                let article = Article(title: post.title, id: post.id!,
                                      url_image: K.getFullAddress() + "images/post/" + post.image,
                                      description: post.description,
                                      Tags: post.tags.map {$0.title},//PostViewController.getTags(post),
                                      Locations: [post.place.country.title, post.place.title])
                let context = Context(index: Index(page),
                                      content: [article],
                                      footer: Footer(),
                                      username: username!.uppercased(),
                                      image_src: ava ?? "not",
                                      lastBids: post.bids.count == 0 ? 0 : post.bids[post.bids.count-1].bid,
                                      bidOwner: isYourBids )
                return req.view.render("post", context)
            }
    }

    
    fileprivate func saveFile(path: String, data: Data) throws {
        
        try? FileManager.default.removeItem(atPath: path)

        if FileManager.default.createFile(atPath: path, contents: data,attributes: nil) {
            debugPrint("saved file\n\t \(path)")
        } else {
            debugPrint ("error")
        }
    }
    
    
    fileprivate func forForm ( _ tags: [Tag]) -> String {
       
        var tagsString = ""
        
        for tag in tags {
            tagsString = tagsString + " #" + tag.title
        }
        
        return tagsString
        
    }

}



struct InContex: Content {
    var title: String
    var description: String
}
