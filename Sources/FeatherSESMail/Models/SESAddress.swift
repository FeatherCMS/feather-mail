struct SESAddress {
    let email: String
    let name: String?

    init(
        _ email: String,
        name: String? = nil
    ) {
        self.email = email
        self.name = name
    }
    
    var mime: String {
        if let name {
            return "\(name) <\(email)>"
        }
        return email
    }
}
