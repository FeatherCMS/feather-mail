import XCTest
import NIO
import FeatherMail
import FeatherSESMail
import SotoCore
import SotoSESv2
import Logging

final class FeatherSESMailTests: XCTestCase {
    
    var from: String { ProcessInfo.processInfo.environment["MAIL_FROM"]! }
    var to: String { ProcessInfo.processInfo.environment["MAIL_TO"]! }
    
    private func send(_ email: FeatherMail) async throws {
        let env = ProcessInfo.processInfo.environment
        
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        var logger = Logger(label: "aws-logger")
        logger.logLevel = .info
        
        let client = AWSClient(
            credentialProvider: .static(
                accessKeyId: env["SES_ID"]!,
                secretAccessKey: env["SES_SECRET"]!
            ),
            options: .init(
                requestLogLevel: .info,
                errorLogLevel: .info
            ),
            httpClientProvider: .createNewWithEventLoopGroup(
                eventLoopGroup
            ),
            logger: logger
        )
        let ses = SESv2(
            client: client,
            region: .init(rawValue: env["SES_REGION"]!)
        )
        let mailer = FeatherSESMailer(
            ses: ses,
            logger: logger,
            eventLoop: eventLoopGroup.any()
        )

        try await mailer.send(email)
        try await client.shutdown()
        try await eventLoopGroup.shutdownGracefully()
    }
    
    // MARK: - test cases
    
    func testSimpleText() async throws {
        let email = try FeatherMail(
            from: FeatherMailAddress(from),
            to: [
                FeatherMailAddress(to),
            ],
            subject: "test ses with simple text",
            body: "This is a simple text email body with SES."
        )
        try await send(email)
    }
    
    func testHMTLText() async throws {
        let email = try FeatherMail(
            from: FeatherMailAddress(from),
            to: [
                FeatherMailAddress(to),
            ],
            subject: "test ses with HTML text",
            body: "This is a <b>HTML text</b> email body with SES.",
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
            subject: "test ses with attachment",
            body: "This is an email body and attachment with SES.",
            attachments: [attachment]
        )
        try await send(email)
    }
}
