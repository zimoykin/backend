import Fluent
import Vapor

final class MessageModel: Model, Content {
    static let schema = "messages"
    
    struct Output: Content {
        
        var id: UUID?
        var message: String
        var user: UserModel.Public
      
        init (params: MessageModel) {
            self.id = params.id
            self.message = params.message
            self.user = params.user.asPublic()
        }
    }

    
    func output () -> MessageModel.Output {
        Output(params: self)
    }
    
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "message")
    var message: String
    
    @OptionalParent(key: "blog_id")
    var blog: BlogModel?
    
    @Parent(key: "user_id")
    var user: UserModel
    
    @OptionalParent(key: "to_user_id")
    var toUser: UserModel?

   
    init() { }

    init(id: UUID? = nil,
         message: String,
         userid: UUID,
         blogid: UUID? = nil,
         touserid: UUID? = nil) {
        self.id = id
        self.message = message
        self.$blog.id = blogid
        self.$user.id = userid
        self.$toUser.id = userid
    }
}
