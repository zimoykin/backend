//
//  File.swift
//  
//
//  Created by Дмитрий on 08.01.2021.
//

import Fluent
import Vapor

final class EmotionsModel: Model, Content {
    static let schema = "emotions"
    
    struct Output: Content {
        var user: UserModel.Public
        var blog_id: UUID
        var image: String
        var emotion: EmotionsType
        
        init (params: EmotionsModel) {
            self.user = params.user.asPublic()
            self.blog_id = params.blog.id!
            self.image = params.getImage ()
            self.emotion = params.emotion
        }
        init (blog_id: UUID,  user: UserModel, emotion: EmotionsModel) {
            self.user = user.asPublic()
            self.blog_id = blog_id
            self.image = emotion.getImage()
            self.emotion = emotion.emotion
        }
    }
    
    
    @ID(key: .id)
    var id: UUID?

    @Enum(key: "emotion")
    var emotion: EmotionsType
    
    @Parent(key: "user_id")
    var user: UserModel
    
    @Parent(key: "blog_id")
    var blog: BlogModel
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(id: UUID? = nil, emotion: EmotionsType, user: UserModel, blogId: UUID) {
        self.id = id
        self.emotion = emotion
        self.$user.id = user.id!
        self.$blog.id = blogId
    }
    
    private func getImage () -> String {
        switch self.emotion {
        case .like:
            return K.getFullAddress() + "images/system/like.png"
        case .dislike:
            return K.getFullAddress() + "images/system/dislike.png"
        case .report:
            return K.getFullAddress() + "images/system/report.png"
        }
    }
    
}
