import SotoSESv2
import FeatherMail

public struct FeatherSESMailer: FeatherMailer {
    let ses: SESv2
    let logger: Logger
    let eventLoop: EventLoop
    
    public init(ses: SESv2, logger: Logger, eventLoop: EventLoop) {
        self.ses = ses
        self.logger = logger
        self.eventLoop = eventLoop
    }
    
    public func send(_ email: FeatherMail) async throws {
        let sesMail = try SESEmail(
            from: SESAddress(email.from.email, name: email.from.name),
            to: email.to.map {
                SESAddress($0.email, name: $0.name)
            },
            cc: email.cc.map {
                SESAddress($0.email, name: $0.name)
            },
            bcc: email.bcc.map {
                SESAddress($0.email, name: $0.name)
            },
            subject: email.subject,
            body: email.body,
            isHtml: email.isHtml,
            replyTo: email.replyTo.map {
                SESAddress($0.email, name: $0.name)
            },
            reference: email.reference,
            attachments: email.attachments.map {
                SESAttachment(
                    name: $0.name,
                    contentType: $0.contentType,
                    data: $0.data
                )
            }
        )

        let rawMessage = SESv2.RawMessage(
            data: AWSBase64Data.base64(sesMail.rawValue)
        )
        let request = SESv2.SendEmailRequest(content: .init(raw: rawMessage))
        _ = try await ses.sendEmail(
            request,
            logger: logger,
            on: eventLoop
        )
    }
}
