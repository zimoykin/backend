import Vapor
import Fluent

final class RefreshToken: Model {
    
    struct Input: Content {
        var refreshToken: String
    }
    
    init() {}
    static let schema = "refreshTokens"
    
    @ID(key: "id")
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: UserModel
    
    @Field(key: "token")
    var token: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
//    @Timestamp(key: "updated_at", on: .update)
//    var updatedAt: Date?
 
    
    init(_ userID: UUID, token: String) {
        self.$user.id = userID
        self.token = token
    }
}
