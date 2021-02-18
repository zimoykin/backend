
@testable import App
import XCTVapor

final class UserTests: XCTestCase {
    
    func userTest () throws {
        print("user test")
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        try app.test(.GET, "hello") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "Hello, world!")
        }
        
    }
    
}
