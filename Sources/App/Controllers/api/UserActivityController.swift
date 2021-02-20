import Fluent
import Vapor

struct UserActivityController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let activity = routes.grouped("api").grouped("activity")
        activity.get(use: index)
        activity.post(use: create)
    }

    func index(req: Request) throws -> EventLoopFuture<[UserActivity]> {
        return UserActivity.query(on: req.db(.mongo)).all()
    }

    func create(req: Request) throws -> EventLoopFuture<UserActivity> {
        let activity = try req.content.decode(UserActivity.self)
        activity.ipAddress = req.remoteAddress?.ipAddress ?? "-"
        return activity.save(on: req.db(.mongo)).map { activity }
    }
    
}
