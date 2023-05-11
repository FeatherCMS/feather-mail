public struct SMTPAddress {
    public let address: String
    public let name: String?

    public init(
        _ address: String,
        name: String? = nil
    ) {
        self.address = address
        self.name = name
    }

    var mime: String {
        if let name {
            return "\(name) <\(address)>"
        }
        return address
    }
}
