  
  import Fluent
  import Vapor
  import JWT
  
  final class UserModel: Model {
    
    static let schema = "users"
    
    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "confirmed")
    var confirmed: Bool
    
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
        self.confirmed = false
    }
  }
  
  extension UserModel {
    
    static func create(from userSignup: UserCredentials) throws -> UserModel {
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
        try (self.confirmed && Bcrypt.verify(password, created: self.passwordHash))
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
        return  UserModel.find(jwt.id, on: request.db(.psql))
            .unwrap(or: Abort(.notFound))
            .map {
                return request.auth.login($0)
            }
    }
    
  }
  
