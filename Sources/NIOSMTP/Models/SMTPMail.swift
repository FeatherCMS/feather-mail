import Foundation
import NIO

public struct SMTPMail {
    public let from: SMTPAddress
    public let to: [SMTPAddress]
    public let cc: [SMTPAddress]
    public let bcc: [SMTPAddress]
    public let subject: String
    public let body: String
    public let isHtml: Bool
    public let replyTo: [SMTPAddress]
    public let reference: String?
    public let attachments: [SMTPAttachment]

    let dateFormatted: String
    let uuid: String

    public init(
        from: SMTPAddress,
        to: [SMTPAddress] = [],
        cc: [SMTPAddress] = [],
        bcc: [SMTPAddress] = [],
        subject: String,
        body: String,
        isHtml: Bool = false,
        replyTo: [SMTPAddress] = [],
        reference: String? = nil,
        attachments: [SMTPAttachment] = []
    ) throws {
        guard !to.isEmpty || !cc.isEmpty || !bcc.isEmpty else {
            throw SMTPMailError.recipientNotSpecified
        }
        self.from = from
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.body = body
        self.isHtml = isHtml
        self.replyTo = replyTo
        self.reference = reference
        self.attachments = attachments

        let date = Date()
        
        // NOTE: this is very inefficient
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"

        dateFormatted = dateFormatter.string(from: date)
        uuid = "<\(date.timeIntervalSince1970)\(from.address.drop { $0 != "@" })>"
    }
    
    ///wrire Email content into a ByteBuffer
    func write(to out: inout ByteBuffer) {
        out.writeString("From: \(from.mime)\r\n")

        let toAddresses = to.map(\.mime).joined(separator: ", ")
        out.writeString("To: \(toAddresses)\r\n")

        let ccAddresses = cc.map(\.mime).joined(separator: ", ")
        out.writeString("Cc: \(ccAddresses)\r\n")

        let replyToAddresses = replyTo.map(\.mime).joined(separator: ", ")
        out.writeString("Reply-to: \(replyToAddresses)\r\n")
        
        out.writeString("Subject: \(subject)\r\n")
        out.writeString("Date: \(dateFormatted)\r\n")
        out.writeString("Message-ID: \(uuid)\r\n")

        if let reference = reference {
            out.writeString("In-Reply-To: \(reference)\r\n")
            out.writeString("References: \(reference)\r\n")
        }

        let boundary = boundary()
        if !attachments.isEmpty {
            out.writeString(
                "Content-type: multipart/mixed; boundary=\"\(boundary)\"\r\n"
            )
            out.writeString("Mime-Version: 1.0\r\n\r\n")
        }
        else if isHtml {
            out.writeString("Content-Type: text/html; charset=\"UTF-8\"\r\n")
            out.writeString("Mime-Version: 1.0\r\n\r\n")
        }
        else {
            out.writeString("Content-Type: text/plain; charset=\"UTF-8\"\r\n")
            out.writeString("Mime-Version: 1.0\r\n\r\n")
        }

        if !attachments.isEmpty {
            if isHtml {
                out.writeString("--\(boundary)\r\n")
                out.writeString(
                    "Content-Type: text/html; charset=\"UTF-8\"\r\n\r\n"
                )
                out.writeString("\(body)\r\n")
                out.writeString("--\(boundary)\r\n")
            }
            else {
                out.writeString("--\(boundary)\r\n")
                out.writeString(
                    "Content-Type: text/plain; charset=\"UTF-8\"\r\n\r\n"
                )
                out.writeString("\(body)\r\n\r\n")
                out.writeString("--\(boundary)\r\n")
            }

            for attachment in attachments {
                out.writeString("Content-type: \(attachment.contentType)\r\n")
                out.writeString("Content-Transfer-Encoding: base64\r\n")
                out.writeString(
                    "Content-Disposition: attachment; filename=\"\(attachment.name)\"\r\n\r\n"
                )
                out.writeString("\(attachment.data.base64EncodedString())\r\n")
                out.writeString("--\(boundary)\r\n")
            }
        }
        else {
            out.writeString(body)
        }
        out.writeString("\r\n.")
    }

    private func boundary() -> String {
        UUID().uuidString
            .replacingOccurrences(of: "-", with: "")
            .lowercased()
    }
}
