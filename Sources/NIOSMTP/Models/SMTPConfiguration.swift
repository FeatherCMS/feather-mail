import NIO

/// Configuration for a SMTP provider
public struct SMTPConfiguration {
    public let hostname: String
    public let port: Int
    public let security: SMTPSecurity
    public let timeout: TimeAmount
    public let helloMethod: HelloMethod
    public let signInMethod: SignInMethod

    public init(
        hostname: String,
        port: Int = 587,
        signInMethod: SignInMethod,
        security: SMTPSecurity = .startTLS,
        timeout: TimeAmount = .seconds(10),
        helloMethod: HelloMethod = .helo
    ) {
        self.hostname = hostname
        self.port = port
        self.security = security
        self.timeout = timeout
        self.helloMethod = helloMethod
        self.signInMethod = signInMethod
    }
}
