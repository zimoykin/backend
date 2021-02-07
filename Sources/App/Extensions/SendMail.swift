
import Vapor
import VaporSMTPKit
import SMTPKitten

struct MailManager {
    
    static func send (_ app: Application, name: String, to: String, subject: String, text: String) {
        
        let email = Mail(
            from: MailUser(name: "noreply", email: K.mailaddress),
            to: [
                MailUser(name: name, email: to)
            ],
            subject: subject,
            contentType: .plain,
            text: text
        )
        
        
        app.sendMail(email, withCredentials: .default).map {
            print("[smtp]: mail send it!")
            app.logger.info("[smtp]: mail send it!")
        }.whenFailure({ error in
            app.logger.error("[smtp]: mail send it!")
            print ("[smtp]: \(error)")
        })
        
    }
}
