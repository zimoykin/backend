import Foundation
import Fluent
import Vapor
import VaporSMTPKit
import SMTPKitten

extension Int {
    
    func toArray () -> [Int]{
        
        var array = [Int]()
        
        if self >= 1 {
            var i = 1
            while i <= self {
                array.append(i)
                i += 1
            }
        }
        
        return array
        
    }
    
}

extension Date {
    func smallPresent() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy MMMM dd"
        return dateFormatter.string(from: self)
    }
}

extension QueryBuilder {
    
    public func withOutput () -> Self {
        
        guard let model = self as? QueryBuilder<BlogModel>
        else { return self }
        
        return model.with(\.$tags)
            .with(\.$user)
            .with(\.$messages, {$0.with(\.$user).with(\.$toUser).with(\.$blog)})
            .with(\.$emotions, { $0.with(\.$blog).with(\.$user)} )
            .with(\.$place, {$0.with(\.$country)})
            .with(\.$bids) as! Self
    }
    
}

extension Application {
    
    public var sockets: Socket {
        get { .init(application: self) }
        set {
            print ("sockets clients: \(newValue.clients.count)")
            _ = self.server.onShutdown.map {
                _ = self.sockets.clients.map {
                    $0.socket.close(code: .normalClosure)
                }
            }
        }
    }
    
    public struct Socket {
        
        private final class Storage {
            var sockets: Set<SocketClient>
            init() {
                self.sockets = .init()
            }
        }

        private struct Key: StorageKey {
            typealias Value = Storage
        }

        public let application: Application
        
        
        public var clients: Set<SocketClient> {
            get { self.storage.sockets }
            set { self.storage.sockets = newValue }
        }

        private var storage: Storage {
            if let existing = self.application.storage[Key.self] {
                return existing
            } else {
                let new = Storage()
                self.application.storage[Key.self] = new
                return new
            }
        }
    }
}

extension SMTPCredentials {
    static var `default`: SMTPCredentials {
        SMTPCredentials(hostname: K.mailhost,
                        port: K.mailport,
                        ssl: .tls(configuration: .default),
                        email: K.mailaddress,
                        password: K.mailsecret)
    }
}
