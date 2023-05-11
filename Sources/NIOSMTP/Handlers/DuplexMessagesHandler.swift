import Foundation
import NIO
import Logging

final class DuplexMessagesHandler: ChannelDuplexHandler {

    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    let logger: Logger?

    init(logger: Logger? = nil) {
        self.logger = logger
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        if let logger {
            let buffer = unwrapInboundIn(data)
            let message = String(
                decoding: buffer.readableBytesView,
                as: UTF8.self
            ).trimmingCharacters(in: .whitespacesAndNewlines)
            logger.info("==> \(message)")
        }
        context.fireChannelRead(data)
    }

    func write(
        context: ChannelHandlerContext,
        data: NIOAny,
        promise: EventLoopPromise<Void>?
    ) {
        if let logger {
            let buffer = unwrapOutboundIn(data)
            let message = String(
                decoding: buffer.readableBytesView,
                as: UTF8.self
            ).trimmingCharacters(in: .whitespacesAndNewlines)
            logger.info("==> \(message)")
        }
        context.write(data, promise: promise)
    }

}
