//
//  File.swift
//  
//
//  Created by Дмитрий on 03.02.2021.
//

import Vapor

class SocketController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        routes.webSocket("api", "ws") { (req, ws) in
            connectWS (req: req, ws: ws)
        }
        
        func connectWS (req: Request, ws: WebSocket)  {
            
            ws.onText  { (_, text) in
                
                guard
                    let userJWT: UserPayload = try? req.jwt.verify(text)
                else {
                    return
                        req.logger.debug("error decode token \(text)")
                }
                _ = UserModel.find(userJWT.id, on: req.db).map {
                    if let user = $0 {
                  
                        let socket = SocketClient(user, ws, req.application)
                        req.application.sockets.clients.insert(socket)
                        print ( req.application.sockets.clients.count )
                    } else {
                        //unauthorized
                        _ = ws.close(code: .goingAway)
                    }
                    
                }
                
            }
        }
    }
    
    
}

public struct SocketClient: Hashable {
    
    var socket: WebSocket
    var user: UserModel.Public
    var app: Application

    public static func == (lhs: SocketClient, rhs: SocketClient) -> Bool {
        return lhs.user.id == rhs.user.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(user.id)
    }

    init ( _ user: UserModel, _ socket: WebSocket, _ app: Application) {
        self.socket = socket
        self.user = user.asPublic()
        self.app = app
        debugPrint("[WS] welcome \(user.id!)")
        socket.send("welcome")
        usersOnline ()
        listenSocket ()
    }

    func usersOnline () {
        if let decoded = try? JSONEncoder().encode(
            self.app.sockets.clients
                    //.filter( {$0 != self })
                    .map { $0.user } ) {
            if let data = String(bytes: decoded, encoding: .utf8) {
                print(data)
                _ = self.app.sockets.clients
                    //.filter( {$0 != self })
                    .map ({
                        $0.socket.send(data)
                    })
            }
        }
    }
    
    func listenSocket () {

        self.socket.onText { _, text in
            print ("\(self.user.id):\(text)")
            switch text {
            case "whoisonline?":
                self.usersOnline()
            default:
                self.socket.send("error")
            }
        }
        
        self.socket.onBinary { (_, data) in
            
            guard let data = try? JSONDecoder() .decode(SocketData.self, from: data)
            else {  self.socket.send("error"); return }
    
            switch data.topic {
            case .users:
                self.usersOnline()
            case .lasttopic:
                self.socket.send("underconstruction")
            case .ad:
                self.socket.send("underconstruction")
            case .bid:
                self.socket.send("underconstruction")
            }
            
        }

        self.socket.pingInterval = .seconds(5)

        _ = self.socket.onClose.map({
            self.app.sockets.clients.remove(self)
            self.usersOnline()
            debugPrint("[WS] goodbye \(self.user.id)")
        })
        
    }

    
    
}


enum SocketTopic: String, Codable, CaseIterable {
    case users = "users"
    case lasttopic = "lasttopic"
    case ad = "ad"
    case bid = "bid"
}


struct SocketData: Codable {
    var topic: SocketTopic
    var body: String
    var user: UUID
}
