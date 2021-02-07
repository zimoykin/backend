import Vapor

final class CorrectAddressMiddleware: Middleware {

    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        if request.url.path.lowercased() != request.url.path {
            let response = request.redirect(to: request.url.path.lowercased(), type: .temporary)
            return request.eventLoop.makeSucceededFuture(response)
        }
        return next.respond(to: request)
    }
}
