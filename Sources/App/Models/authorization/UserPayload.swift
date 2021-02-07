import JWT
import Vapor

struct UserPayload: JWTPayload {
    
    var id: UUID
    var name: String
    var exp: ExpirationClaim
    
    func verify(using signer: JWTSigner) throws {
        try self.exp.verifyNotExpired()
    }
}
