  
  import Fluent
  import Vapor
  import JWT
  
  final class UserModel: Model {
    
    struct Public: Content {
        let username: String
        let id: UUID
        let createdAt: Date?
        let updatedAt: Date?
        var email: String
        let image: String
    }
    
    struct OutputLogin: Content {
        
        let username: String
        let id: UUID
        let accessToken: String
        let refreshToken: String
        let image: String
        
        init (_ user: UserModel, req: Request) throws {
            
            self.username = user.username
            self.id = user.id!
            self.accessToken = try user.createToken(req.application, isAccess: true)
            self.refreshToken = try user.createToken(req.application, isAccess: false)
            self.image = user.getSourceImage()
            
            let ref = RefreshToken(user.id!, token: self.refreshToken).save(on: req.db)
            debugPrint(ref)
            
        }
    }
    
    struct FullOutput: Content {
        let username: String
        var image: String
        let id: UUID
        let createdAt: Date?
        var email: String
        var blogs: [BlogModel.Output]
        init (user: UserModel) {
            self.username = user.username
            self.id = user.id!
            self.createdAt = user.createdAt
            self.email = user.email
            self.blogs = user.blogs.map { BlogModel.Output($0) }
            self.image = user.getSourceImage()
        }
    }
    
    static let schema = "users"
    
    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "email")
    var email: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Children (for: \.$user) var bids: [BidModel]
    @Children(for: \.$user) var blogs: [BlogModel]
    
    init() {}
    
    init(id: UserModel.IDValue? = nil, username: String, passwordHash: String, email: String) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
        self.email = email
    }
  }
  
  extension UserModel {
    
    static func create(from userSignup: UserSignup) throws -> UserModel {
        UserModel(username: userSignup.username,
                  passwordHash: try Bcrypt.hash(userSignup.password),
                  email: userSignup.email)
    }
    
    func asPublic() -> Public {
        Public(username: username,
               id: self.id!,
               createdAt: createdAt,
               updatedAt: updatedAt,
               email: email,
               image: self.getSourceImage())
    }
    
    func getSourceImage() -> String {
        return K.getFullAddress() + "images/avatars/" + self.id!.uuidString + ".jpg"
    }
    
    func createToken (_ app: Application, isAccess: Bool) throws -> String {
        
        var expDate = Date()
        expDate.addTimeInterval( isAccess ? 3600 * 2 : 86400 * 14)
        let exp = ExpirationClaim(value: expDate)
        
        return try app.jwt.signers.sign(UserPayload(id: self.id!, name: self.username, exp: exp))
        
    }
    
  }
  
  extension UserModel: ModelAuthenticatable {
    
    static let usernameKey = \UserModel.$username
    static let passwordHashKey = \UserModel.$passwordHash
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
    
  }
  
  extension UserModel: SessionAuthenticatable {
    typealias SessionID = UUID
    var sessionID: SessionID { self.id! }
  }
  
  extension UserModel: Authenticatable {
    
  }
  
  struct UserAuthenticatorJWT: JWTAuthenticator {
    
    typealias Payload = UserPayload
    
    func authenticate(jwt: UserPayload, for request: Request) -> EventLoopFuture<Void> {
        try! jwt.verify(using: request.application.jwt.signers.get()!)
        return  UserModel.find(jwt.id, on: request.db)
            .unwrap(or: Abort(.notFound))
            .map {
                return request.auth.login($0)
            }
    }
    
  }
  
  struct UserLogin: Content {
    let login: String
    let password: String
  }
  
  
  struct UserSignup: Content, Validatable{
    
    let username: String
    let email: String
    let password: String
    
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(5...))
        validations.add("email", as: String.self, is: .email)
    }
  }
