import Fluent
import Vapor

final class BidModel: Model, Content {
    static let schema = "bids"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "bid")
    var bid: Int
    
    @Parent(key: "user_id")
    var user: UserModel
    
    @Parent(key: "blog_id")
    var blog: BlogModel
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }

    init(id: UUID? = nil, bid: Int, userID: UUID, blogID: UUID) {
        self.id = id
        self.bid = bid
        self.$user.id = userID
        self.$blog.id = blogID
    }
}

