
import Vapor
import Fluent
//import ImageResizable

struct BlogController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let api_path = routes.grouped("api")
            .grouped("blogs")
            .grouped(UserAuthenticatorJWT())
        
        api_path.get    (use: index)
        api_path.get    ("list", use: indexSimple)
        api_path.get    ("images", "list", use: indexImageList)
        api_path.get    ("onday", ":day", use: getOnDay)
        api_path.get    ("id", use: blog)
        api_path.post   (use: create)
        //only 10mb
        api_path.on     (.POST, "uploads", body: .collect(maxSize: 10_000_000), use: uploadImage)
        //api_path.post   (":postID", "crop", use: resizeImage)
        api_path.put    (use: update)
        api_path.delete (use: delete)
        
    }
    
    
    func index (_ req: Request) throws -> EventLoopFuture<[BlogModel.Output]> {
        
        try req.auth.require(UserModel.self)
        
        return BlogModel.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .with(\.$place, {
                    $0.with(\.$country)})
            .with(\.$tags)
            .with(\.$messages)
            .with(\.$user)
            .with(\.$bids)
            .with(\.$emotions, { $0.with(\.$blog).with(\.$user)} )
            .all().mapEach {
                BlogModel.Output($0)
            }
        
    }
    
    func indexSimple (_ req: Request) throws -> EventLoopFuture<Page<String>> {
        
        try req.auth.require(UserModel.self)
        
        return BlogModel.query(on: req.db)
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
    
    func getOnDay ( _ req: Request) throws -> EventLoopFuture<[BlogModel.Output]> {
        
        try req.auth.require(UserModel.self)
        
        guard let day = req.parameters.get("day")
        else { throw Abort (.badRequest, reason: "missing params date") }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        guard let dateStart = formatter.date(from: day),
              var dateFinish = formatter.date(from: day)
        else { throw (Abort (.badRequest))}
        
        dateFinish.addTimeInterval(Double(86400))
        
        return BlogModel.query(on: req.db)
            .group(.and){ and in
                and.filter (\.$createdAt >= dateStart)
                and.filter(\.$createdAt < dateFinish)
            }
            .sort(\.$createdAt, .descending)
            .with(\.$place, {
                    $0.with(\.$country)})
            .with(\.$tags)
            .with(\.$messages)
            .with(\.$user)
            .with(\.$emotions, { $0.with(\.$blog).with(\.$user)} )
            .with(\.$bids)
            .all().mapEach {
                BlogModel.Output($0)
            }
        
    }
    
    func blog (_ req: Request) throws -> EventLoopFuture<BlogModel.Output> {
        
        try req.auth.require(UserModel.self)
        
        guard let blogid = getBlogIDQuery(req)
        else { return req.eventLoop.makeFailedFuture(Abort(.badRequest)) }
        
        return BlogModel.query(on: req.db)
            .filter(\.$id == blogid)
            .withOutput()
            .first()
            .unwrap(or: Abort (.notFound) ).map {
                BlogModel.Output($0, short: false)
            }
        
    }
    
    func update ( req: Request) throws -> EventLoopFuture<BlogModel.Output> {
        
        guard let user = req.auth.get(UserModel.self)
        else { throw Abort (.unauthorized) }
        
        guard let blogid = getBlogIDQuery(req)
        else { return req.eventLoop.makeFailedFuture(Abort(.badRequest)) }
        
        guard let body = req.body.data,
              let data = try? JSONDecoder().decode(PostData.self, from: body)
        else { throw Abort (.badRequest) }
        
        let tags = data.tags.components(separatedBy: "#")
        
        return BlogModel.query(on: req.db)
            .filter(\.$id==blogid)
            .filter(\.$user.$id==user.id!)
            .withOutput()
            .first()
            .unwrap(or: Abort(.notFound))
            .map { blog -> BlogModel.Output in
                blog.title = data.title
                blog.description = data.description
                blog.$place.id = data.placeId
                
                if data.tags != "" {
                    //delete old hashtags
                    _ = blog.$tags.detach( blog.tags.compactMap { $0 }, on: req.db).map {
                        for tag in tags {
                            if tag.replacingOccurrences(of: " ", with: "").count > 0 {
                                _ = Tag.query(on: req.db).filter(\.$title, .equal, tag.replacingOccurrences(of: " ", with: "")).first().flatMapThrowing { (tagModel) in
                                    if tagModel == nil {
                                        let newTag = Tag(title: tag.replacingOccurrences(of: " ", with: ""))
                                        _ = newTag.save(on: req.db).map {
                                            _ = blog.$tags.attach(newTag, on: req.db)
                                        }
                                    } else  {
                                        _ = blog.$tags.attach(tagModel!, on: req.db)
                                    }
                                }
                            }
                        }
                    }
                }
                
                _ = blog.save(on: req.db)
                return BlogModel.Output(blog)
                
            }
        
    }
    
    func create (_ req: Request) throws -> EventLoopFuture<BlogModel.Output> {
        
        guard let user = req.auth.get(UserModel.self) else {
            throw Abort (.unauthorized)
        }
        
        //let data = try req.content.decode(PostData.self)
        let data = try JSONDecoder().decode(PostData.self, from: req.body.data!)
        let tags = data.tags.components(separatedBy: "#")
        
        let post = BlogModel(title: data.title, description: data.description, user_id: user.id!, image: "", place_id: data.placeId)
        return post.save(on: req.db)
            .flatMap { _ -> EventLoopFuture<BlogModel.Output> in
            for tag in tags {
                if tag.replacingOccurrences(of: " ", with: "").count > 0 {
                    
                    _ = Tag.query(on: req.db)
                        .filter(\.$title, .equal, tag.replacingOccurrences(of: " ", with: ""))
                        .first()
                        .flatMapThrowing { (tagModel) in
                        if tagModel == nil {
                            let newTag = Tag(title: tag.replacingOccurrences(of: " ", with: ""))
                            _ = newTag.save(on: req.db).map {
                                post.$tags.attach(newTag, on: req.db)
                            }
                        } else  {
                            _ = post.$tags.attach(tagModel!, on: req.db)
                        }
                    }
                }
            }
            return BlogModel.query(on: req.db)
                .filter(\.$id==post.id!)
                .withOutput()
                .first()
                .unwrap(or: Abort (.notFound))
                .map { blog -> BlogModel.Output in
                    _ = req.application.sockets.clients.map {
                        $0.socket.send("new blog available!")
                    }
                    return BlogModel.Output(blog)
                }
        }
    }
    
    func uploadImage (req: Request) throws -> EventLoopFuture<BlogModel.Output> {
        
        try req.auth.require(UserModel.self)
        
        guard let user = req.auth.get(UserModel.self)
        else { throw Abort (.unauthorized) }
        
        struct inputFile: Codable {
            var file: Data
            var filename: String
        }
        struct inputData: Content {
            var blogid: String
            var asMain: Bool
        }
        
        guard let data = try? req.query.decode(inputData.self),
              let id = UUID(uuidString: data.blogid )
        else { throw Abort (.badRequest, reason: "error params")  }
        
        
        guard let file = try? req.content.decode(inputFile.self)
        else { throw Abort (.badRequest, reason: "error input file") }
        
        let saved = req.eventLoop.makePromise(of: BlogModel.Output.self )
        
        _ = BlogModel.query(on: req.db)
            .filter(\.$id == id)
            .filter(\.$user.$id == user.id!)
            .withOutput()
            .first()
            .unwrap(or: Abort (.notFound))
            .map { blog in
                
                self.saveFile(req: req, blog: blog, data: file.file, filename: file.filename) { blog_output in
                    if blog_output != nil {
                        if data.asMain {
                            blog.image = "\(file.filename)"
                            _ = blog.save(on: req.db).map {
                                saved.succeed( blog_output! )
                            }
                        } else {
                            saved.succeed( blog_output! )
                        }
                    } else {
                        saved.fail(Abort (.internalServerError))
                    }
                }
            }
        
        return saved.futureResult
    }
    
    fileprivate func saveFile (req: Request, blog: BlogModel, data: Data, filename: String, isSquare: Bool = false, completionHandler: @escaping (BlogModel.Output?) -> Void )  {
        
        let pathFolder = req.application.directory.publicDirectory + "images/blog/\(blog.id!)"
        if !FileManager.default.fileExists(atPath: pathFolder) {
            try? FileManager.default.createDirectory(at: URL(fileURLWithPath: pathFolder), withIntermediateDirectories: true)
        }
        
        if FileManager.default.createFile(atPath: "\(pathFolder)/\(filename)", contents: data, attributes: nil) {
            debugPrint("saved \(pathFolder)/\(filename)")
            completionHandler (BlogModel.Output (blog))
            
        } else {
            debugPrint ("error")
            completionHandler(nil)
        }
    }
    
    fileprivate func deleteFile (req: Request, blog: BlogModel, full: Bool,   completionHandler: @escaping () -> Void )  {
        
        if full {
            let path = req.application.directory.publicDirectory + "images/blog/\(blog.id!)"
            try? FileManager.default.removeItem(atPath: path)
            debugPrint("deleted: " + path)
            completionHandler()
        } else {
            let pathMain = req.application.directory.publicDirectory + "images/blog/\(blog.id!)/\(blog.image)"
            try? FileManager.default.removeItem(atPath: pathMain)
            debugPrint("deleted: " + pathMain)
            completionHandler()
        }
        
    }
    
    func delete (req: Request) throws -> EventLoopFuture<HTTPStatus> {
        
        guard let user = req.auth.get(UserModel.self)
        else { throw Abort (.unauthorized) }
        
        struct inputData: Content {
            var blogid: String
        }
        
        guard let input = try? req.query.decode(inputData.self)
        else { throw Abort (.badRequest) }
        guard let blogID = UUID (uuidString: input.blogid)
        else { throw Abort (.badRequest) }
        
        return BlogModel.query(on: req.db)
            .filter(\.$id==blogID)
            .filter(\.$user.$id==user.id!)
            .first()
            .unwrap(or: Abort(.notFound))
            .map { blog in
                self.deleteFile(req: req, blog: blog, full: true) {
                    _ = blog.delete(on: req.db) }
            }
            .transform(to: .ok)
        
    }
    
    
    func indexImageList ( _ req: Request ) throws -> EventLoopFuture<[String]> {
        
        try req.auth.require(UserModel.self)
        
        guard let blogid = getBlogIDQuery(req)
        else { return req.eventLoop.makeFailedFuture(Abort(.badRequest)) }
        
        return BlogModel.query(on: req.db)
            .filter(\.$id==blogid)
            .first()
            .unwrap(or: Abort(.notFound) )
            .flatMapThrowing { blog in
                let fm = FileManager.default
                let path = req.application.directory.publicDirectory + "images/blog/\(blog.id!)"
                if fm.fileExists(atPath: path) {
                    return try fm.contentsOfDirectory(atPath: path)
                        .filter({ !$0.starts(with: ".") })
                        .compactMap { blog.getImageFoldder() + $0 }
                } else {
                    throw Abort (.notFound)
                }
            }
    
}
    
    
     func getBlogIDQuery ( _ req: Request) -> UUID? {
        
        struct inputData: Content {
            var blogid: String
        }
        
        guard let input = try? req.query.decode(inputData.self)
        else { return nil }
        guard let blogID = UUID (uuidString: input.blogid)
        else { return nil }
        
        return blogID
    }
    
}
