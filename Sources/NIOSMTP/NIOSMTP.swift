import NIO
import Logging

/// Send an Email with an SMTP provider
public struct NIOSMTP {

    public let eventLoopGroup: EventLoopGroup
    public let config: SMTPConfiguration
    public let logger: Logger?

    public init(
        eventLoopGroup: EventLoopGroup,
        configuration: SMTPConfiguration,
        logger: Logger?
    ) {
        self.eventLoopGroup = eventLoopGroup
        self.config = configuration
        self.logger = logger
    }

    ///
    /// Send an Email with SMTPSender
    ///
    /// - Parameter email: Email struct to send
    ///
    public func send(_ email: SMTPMail) async throws {
        let result = try await sendWithPromise(email: email).get()
        switch result {
        case .success(_):
            break
        case .failure(let error):
            throw error
        }
    }

    ///
    /// Shutdown the EventLoopGroup
    ///
    public func shutdown() throws {
        try eventLoopGroup.syncShutdownGracefully()
    }

    private func sendWithPromise(
        email: SMTPMail
    ) throws -> EventLoopFuture<Result<Bool, Error>> {
        let eventLoop = eventLoopGroup.next()
        let promise: EventLoopPromise<Void> = eventLoop.makePromise()
        let bootstrap = ClientBootstrap(group: eventLoop)
            .connectTimeout(config.timeout)
            .channelOption(
                ChannelOptions.socket(
                    SocketOptionLevel(SOL_SOCKET),
                    SO_REUSEADDR
                ),
                value: 1
            )
            .channelInitializer { channel in
                let secureChannelFuture = config.security.configureChannel(
                    on: channel,
                    hostname: config.hostname
                )
                return secureChannelFuture.flatMap {
                    let defaultHandlers: [ChannelHandler] = [
                        DuplexMessagesHandler(logger: logger),
                        ByteToMessageHandler(InboundLineBasedFrameDecoder()),
                        InboundSmtpResponseDecoder(),
                        MessageToByteHandler(OutboundSmtpRequestEncoder()),
                        StartTLSHandler(
                            configuration: config,
                            promise: promise
                        ),
                        InboundSendEmailHandler(
                            config: config,
                            email: email,
                            promise: promise
                        ),
                    ]
                    return channel.pipeline.addHandlers(
                        defaultHandlers,
                        position: .last
                    )
                }
            }

        let connection = bootstrap.connect(
            host: config.hostname,
            port: config.port
        )
        connection.cascadeFailure(to: promise)

        return promise.futureResult.map { () -> Result<Bool, Error> in
            connection.whenSuccess { $0.close(promise: nil) }
            return .success(true)
        }
        .flatMapError { error -> EventLoopFuture<Result<Bool, Error>> in
            return eventLoop.makeSucceededFuture(.failure(error))
        }
    }

}
