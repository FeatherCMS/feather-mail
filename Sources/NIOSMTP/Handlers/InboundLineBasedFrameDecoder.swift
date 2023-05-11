import NIO

final class InboundLineBasedFrameDecoder: ByteToMessageDecoder {

    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer
    
    private var cumulationBuffer: ByteBuffer?
    private var lastScanOffset = 0
    private var handledLeftovers = false

    init() {}

    func decode(
        context: ChannelHandlerContext,
        buffer: inout ByteBuffer
    ) -> DecodingState {
        if let frame = findNextFrame(buffer: &buffer) {
            context.fireChannelRead(wrapInboundOut(frame))
            return .continue
        }
        return .needMoreData
    }

    private func findNextFrame(buffer: inout ByteBuffer) -> ByteBuffer? {
        let view = buffer.readableBytesView.dropFirst(lastScanOffset)

        if let delimiterIndex = view.firstIndex(of: 0x0A) {  // '\n'
            let length = delimiterIndex - buffer.readerIndex
            let dropCarriageReturn =
                delimiterIndex > view.startIndex
                && view[delimiterIndex - 1] == 0x0D  // '\r'
            let buff = buffer.readSlice(
                length: dropCarriageReturn ? length - 1 : length
            )
            buffer.moveReaderIndex(forwardBy: dropCarriageReturn ? 2 : 1)
            lastScanOffset = 0

            return buff
        }
        lastScanOffset = buffer.readableBytes
        return nil
    }

    func handlerRemoved(context: ChannelHandlerContext) {
        handleLeftOverBytes(context: context)
    }

    func channelInactive(context: ChannelHandlerContext) {
        handleLeftOverBytes(context: context)
    }

    private func handleLeftOverBytes(context: ChannelHandlerContext) {
        if let buffer = cumulationBuffer,
            buffer.readableBytes > 0 && !handledLeftovers
        {
            handledLeftovers = true
            context.fireErrorCaught(
                NIOExtrasErrors.LeftOverBytesError(leftOverBytes: buffer)
            )
        }
    }
}
