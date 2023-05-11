import XCTest
import NIO
import NIOSMTP
import FeatherMail
import FeatherSMTPMail
import Logging

final class FeatherSMTPMailTests: XCTestCase {
    
    var from: String { ProcessInfo.processInfo.environment["MAIL_FROM"]! }
    var to: String { ProcessInfo.processInfo.environment["MAIL_TO"]! }
    
    private func send(_ email: FeatherMail) async throws {
        let env = ProcessInfo.processInfo.environment
        let logger = Logger(label: "test-logger")
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let smtp = NIOSMTP(
            eventLoopGroup: eventLoopGroup,
            configuration: .init(
                hostname: env["SMTP_HOST"]!,
                signInMethod: .credentials(
                    username: env["SMTP_USER"]!,
                    password: env["SMTP_PASS"]!
                )
            ),
            logger: logger
        )
        let mailer = FeatherSMTPMailer(
            smtp: smtp,
            logger: logger,
            eventLoop: eventLoopGroup.any()
        )
        try await mailer.send(email)
        try await eventLoopGroup.shutdownGracefully()
    }
    
    // MARK: - test cases

    func testSimpleText() async throws {
        let email = try FeatherMail(
            from: FeatherMailAddress(from),
            to: [
                FeatherMailAddress(to),
            ],
            subject: "test SMTP with simple text",
            body: "This is a simple text email body with SMTP."
        )
        try await send(email)
    }
    
    func testHMTLText() async throws {
        let email = try FeatherMail(
            from: FeatherMailAddress(from),
            to: [
                FeatherMailAddress(to),
            ],
            subject: "test SMTP with HTML text",
            body: "This is a <b>HTML text</b> email body with SMTP.",
            isHtml: true
        )
        try await send(email)
    }
    
    func testAttachment() async throws {
        let packageRootPath = URL(fileURLWithPath: #file)
            .pathComponents
            .prefix(while: { $0 != "Tests" })
            .joined(separator: "/")
            .dropFirst()
        let assetsUrl = URL(fileURLWithPath: String(packageRootPath))
            .appendingPathComponent("Tests")
            .appendingPathComponent("Assets")
        let testData = try Data(
            contentsOf: assetsUrl.appendingPathComponent("feather.png")
        )
        let attachment = FeatherMailAttachment(
            name: "feather.png",
            contentType: "image/png",
            data: testData
        )

        let email = try FeatherMail(
            from: FeatherMailAddress(from),
            to: [
                FeatherMailAddress(to),
            ],
            subject: "test SMTP with attachment",
            body: "This is an email body and attachment with SMTP.",
            attachments: [attachment]
        )
        try await send(email)
    }
}
