import NIO
import NIOSSL

final class StartTLSHandler: ChannelDuplexHandler,
    RemovableChannelHandler
{
    typealias InboundIn = SMTPResponse
    typealias InboundOut = SMTPResponse
    typealias OutboundIn = SMTPRequest
    typealias OutboundOut = SMTPRequest

    private let config: SMTPConfiguration
    private let allDonePromise: EventLoopPromise<Void>
    private var waitingForStartTlsResponse = false

    init(
        configuration: SMTPConfiguration,
        promise: EventLoopPromise<Void>
    ) {
        config = configuration
        allDonePromise = promise
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        guard config.security.isStartTLSEnabled else {
            return context.fireChannelRead(data)
        }

        if waitingForStartTlsResponse {
            waitingForStartTlsResponse = false

            let result = unwrapInboundIn(data)
            switch result {
            case .error(let message):
                if config.security == .startTLS {
                    return allDonePromise.fail(SMTPError(message))
                }
                let startTlsResult = wrapInboundOut(
                    .ok(200, "STARTTLS is not supported")
                )
                return context.fireChannelRead(startTlsResult)
            case .ok:
                initializeTlsHandler(context: context, data: data)
            }
        }
        else {
            context.fireChannelRead(data)
        }
    }

    func write(
        context: ChannelHandlerContext,
        data: NIOAny,
        promise: EventLoopPromise<Void>?
    ) {
        guard config.security.isStartTLSEnabled else {
            return context.write(data, promise: promise)
        }

        let command = unwrapOutboundIn(data)
        switch command {
        case .startTLS:
            waitingForStartTlsResponse = true
        default:
            break
        }

        context.write(data, promise: promise)
    }

    private func initializeTlsHandler(
        context: ChannelHandlerContext,
        data: NIOAny
    ) {
        do {
            let sslContext = try NIOSSLContext(
                configuration: .makeClientConfiguration()
            )
            let sslHandler = try NIOSSLClientHandler(
                context: sslContext,
                serverHostname: config.hostname
            )
            _ = context.channel.pipeline.addHandler(
                sslHandler,
                name: "NIOSSLClientHandler",
                position: .first
            )

            context.fireChannelRead(data)
            _ = context.channel.pipeline.removeHandler(self)
        }
        catch let error {
            allDonePromise.fail(error)
        }
    }
}
