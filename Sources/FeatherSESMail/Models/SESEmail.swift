import Foundation

struct SESEmail {
    let from: SESAddress
    let to: [SESAddress]
    let cc: [SESAddress]
    let bcc: [SESAddress]
    let subject: String
    let body: String
    let isHtml: Bool
    let replyTo: [SESAddress]
    let reference: String?
    let attachments: [SESAttachment]
    
    let dateFormatted: String
    let uuid: String

    init(
        from: SESAddress,
        to: [SESAddress] = [],
        cc: [SESAddress] = [],
        bcc: [SESAddress] = [],
        subject: String,
        body: String,
        isHtml: Bool = false,
        replyTo: [SESAddress] = [],
        reference: String? = nil,
        attachments: [SESAttachment] = []
    ) throws {
        guard !to.isEmpty || !cc.isEmpty || !bcc.isEmpty else {
            throw SESMailError.recipientNotSpecified
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
        uuid = "<\(date.timeIntervalSince1970)\(from.email.drop { $0 != "@" })>"
    }
    
    var rawValue: String {
        var out: String = ""
        out += "From: \(from.mime)\r\n"

        let toAddresses = to.map(\.mime).joined(separator: ", ")
        out += "To: \(toAddresses)\r\n"

        let ccAddresses = cc.map(\.mime).joined(separator: ", ")
        out += "Cc: \(ccAddresses)\r\n"

        let replyToAddresses = replyTo.map(\.mime).joined(separator: ", ")
        out += "Reply-to: \(replyToAddresses)\r\n"
        
        out += "Subject: \(subject)\r\n"
        out += "Date: \(dateFormatted)\r\n"
        out += "Message-ID: \(uuid)\r\n"

        if let reference = reference {
            out += "In-Reply-To: \(reference)\r\n"
            out += "References: \(reference)\r\n"
        }

        let boundary = boundary()
        if !attachments.isEmpty {
            out +=
                "Content-type: multipart/mixed; boundary=\"\(boundary)\"\r\n"
            
            out += "Mime-Version: 1.0\r\n\r\n"
        }
        else if isHtml {
            out += "Content-Type: text/html; charset=\"UTF-8\"\r\n"
            out += "Mime-Version: 1.0\r\n\r\n"
        }
        else {
            out += "Content-Type: text/plain; charset=\"UTF-8\"\r\n"
            out += "Mime-Version: 1.0\r\n\r\n"
        }

        if !attachments.isEmpty {
            if isHtml {
                out += "--\(boundary)\r\n"
                out +=
                    "Content-Type: text/html; charset=\"UTF-8\"\r\n\r\n"
                
                out += "\(body)\r\n"
                out += "--\(boundary)\r\n"
            }
            else {
                out += "--\(boundary)\r\n"
                out +=
                    "Content-Type: text/plain; charset=\"UTF-8\"\r\n\r\n"
                
                out += "\(body)\r\n\r\n"
                out += "--\(boundary)\r\n"
            }

            for attachment in attachments {
                out += "Content-type: \(attachment.contentType)\r\n"
                out += "Content-Transfer-Encoding: base64\r\n"
                out +=
                    "Content-Disposition: attachment; filename=\"\(attachment.name)\"\r\n\r\n"
                
                out += "\(attachment.data.base64EncodedString())\r\n"
                out += "--\(boundary)\r\n"
            }
        }
        else {
            out += body
        }
        out += "\r\n."
        
        let utf8str = out.data(using: .utf8)
        if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
            return base64Encoded
        }
        return ""
    }
    
    private func boundary() -> String {
        UUID().uuidString
            .replacingOccurrences(of: "-", with: "")
            .lowercased()
    }
    
}
