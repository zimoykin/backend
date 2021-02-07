import Fluent
import Vapor

final class BlogModel: Model, Content {
    
    struct Output: Content {
        
        var id: UUID?
        var title: String
        var description: String
        var isActive: Bool
        var user: UserModel.Public
        var image: String
        var place: Place
        var lastBid: Int
        var created: String
        var tags: [String]
        var emotions: [EmotionsModel.Output]
        var messages: [MessageModel.Output]
        
        init (_ params: BlogModel, short: Bool = true) {
            self.id = params.id!
            self.title = params.title
            self.description = short ? params.description.getShortDescription() : params.description
            self.isActive = params.isActive
            self.user = params.user.asPublic()
            self.image = params.getImageAddress()
            self.place = params.place
            self.created = params.createdAt!.smallPresent()
            self.lastBid = params.bids.last?.bid ?? 0
            self.tags = params.tags.map { $0.title }
            self.emotions = params.emotions.map{ EmotionsModel.Output(params: $0)}
            self.messages = params.messages.map{ MessageModel.Output(params: $0)}

        }

    }
    
    static let schema = "posts"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "is_active")
    var isActive: Bool
    
    @Field(key: "ranking")
    var ranking: Int
    
    @Parent(key: "user_id")
    var user: UserModel
    
    @Field(key: "image")
    var image: String

    @Parent(key: "place_id")
    var place: Place
    
    @Siblings(through: BlogTag.self, from: \.$blog, to: \.$tag)
    public var tags: [Tag]
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Children(for: \.$blog)     var bids: [BidModel]
    @Children(for: \.$blog)     var emotions: [EmotionsModel]
    @Children (for: \.$blog)    var messages: [MessageModel]

    init() { }

    init(id: UUID? = nil, title: String, description: String, user_id: UUID, image: String, place_id: UUID, isActive: Bool = true) {
        self.id = id
        self.title = title
        self.description = description
        self.image = image
        self.$place.id = place_id
        self.isActive = isActive
        self.$user.id = user_id
        self.ranking = 0
    }
    
    func getImageAddress () -> String {
       K.getFullAddress() + "images/blog/\(self.id!)/" + self.image
    }
    func getImageFoldder () -> String {
       K.getFullAddress() + "images/blog/\(self.id!)/"
    }
    
}


struct PostData: Content {
    var title: String
    var description: String
    var image: Data?
    var placeId: UUID
    var tags: String
}

