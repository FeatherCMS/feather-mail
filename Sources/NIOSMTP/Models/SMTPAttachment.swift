import Foundation

public struct SMTPAttachment {
    public let name: String
    public let contentType: String
    public let data: Data

    public init(
        name: String,
        contentType: String,
        data: Data
    ) {
        self.name = name
        self.contentType = contentType
        self.data = data
    }
}
