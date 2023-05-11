public struct FeatherMail {
    public let from: FeatherMailAddress
    public let to: [FeatherMailAddress]
    public let cc: [FeatherMailAddress]
    public let bcc: [FeatherMailAddress]
    public let subject: String
    public let body: String
    public let isHtml: Bool
    public let replyTo: [FeatherMailAddress]
    public let reference: String?
    public let attachments: [FeatherMailAttachment]
    
    public init(
        from: FeatherMailAddress,
        to: [FeatherMailAddress] = [],
        cc: [FeatherMailAddress] = [],
        bcc: [FeatherMailAddress] = [],
        subject: String,
        body: String,
        isHtml: Bool = false,
        replyTo: [FeatherMailAddress] = [],
        reference: String? = nil,
        attachments: [FeatherMailAttachment] = []
    ) throws {
        guard !to.isEmpty || !cc.isEmpty || !bcc.isEmpty else {
            throw FeatherMailerError.recipientNotSpecified
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
    }
    
}
