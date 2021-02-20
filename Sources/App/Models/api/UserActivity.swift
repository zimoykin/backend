import Fluent
import Vapor

final class UserActivity: Model, Content {
    static let schema = "user_activity"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "user_id")
    var user: UUID
    
    @Enum(key: "type_activity")
    var typeActivity: TypeUserActivity
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Field(key: "ip_address")
    var ipAddress: String?

    init() { }

    init(id: UUID? = nil, user: UUID) {
        self.id = id
        self.user = user
    }
}

enum TypeUserActivity: String, Content {
    case login
    case logout
}
