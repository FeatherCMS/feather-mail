public protocol FeatherMailer {
    func send(_ email: FeatherMail) async throws
}
