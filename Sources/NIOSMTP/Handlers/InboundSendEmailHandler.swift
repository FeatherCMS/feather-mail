import NIO
import NIOSSL

final class InboundSendEmailHandler: ChannelInboundHandler {
    typealias InboundIn = SMTPResponse
    typealias OutboundOut = SMTPRequest

    enum Expect {
        case initialMessageFromServer
        case okAfterHello
        case okAfterStartTls
        case okAfterStartTlsHello
        case okAfterAuthBegin
        case okAfterUsername
        case okAfterPassword
        case okAfterMailFrom
        case okAfterRecipient
        case okAfterDataCommand
        case okAfterMailData
        case okAfterQuit
        case nothing
        case error
    }

    private var currentlyWaitingFor = Expect.initialMessageFromServer
    private let email: SMTPMail
    private let config: SMTPConfiguration
    private let promise: EventLoopPromise<Void>
    private var recipients: [SMTPAddress] = []

    init(
        config: SMTPConfiguration,
        email: SMTPMail,
        promise: EventLoopPromise<Void>
    ) {
        self.config = config
        self.email = email
        self.promise = promise
        self.recipients += email.to
        self.recipients += email.cc
        self.recipients += email.bcc
    }

    func send(context: ChannelHandlerContext, command: SMTPRequest) {
        context.writeAndFlush(wrapOutboundOut(command)).cascadeFailure(
            to: promise
        )
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let result = unwrapInboundIn(data)
        switch result {
        case .error(let message):
            promise.fail(SMTPError(message))
            return
        case .ok:
            ()
        }

        switch currentlyWaitingFor {
        case .initialMessageFromServer:
            send(
                context: context,
                command: .sayHello(
                    serverName: config.hostname,
                    helloMethod: config.helloMethod
                )
            )
            currentlyWaitingFor = .okAfterHello
        case .okAfterHello:
            if config.security.isStartTLSEnabled {
                send(context: context, command: .startTLS)
                currentlyWaitingFor = .okAfterStartTls
            }
            else {
                switch config.signInMethod {
                case .credentials(_, _):
                    send(context: context, command: .beginAuthentication)
                    currentlyWaitingFor = .okAfterAuthBegin
                case .anonymous:
                    send(
                        context: context,
                        command: .mailFrom(email.from.address)
                    )
                    currentlyWaitingFor = .okAfterMailFrom
                }
            }
        case .okAfterStartTls:
            send(
                context: context,
                command: .sayHelloAfterTLS(
                    serverName: config.hostname,
                    helloMethod: config.helloMethod
                )
            )
            currentlyWaitingFor = .okAfterStartTlsHello
        case .okAfterStartTlsHello:
            send(context: context, command: .beginAuthentication)
            currentlyWaitingFor = .okAfterAuthBegin
        case .okAfterAuthBegin:
            switch config.signInMethod {
            case .credentials(let username, _):
                send(context: context, command: .authUser(username))
                currentlyWaitingFor = .okAfterUsername
            case .anonymous:
                promise.fail(
                    SMTPError(
                        "After auth begin executed for anonymous sign in method"
                    )
                )
                break
            }
        case .okAfterUsername:
            switch config.signInMethod {
            case .credentials(_, let password):
                send(context: context, command: .authPassword(password))
                currentlyWaitingFor = .okAfterPassword
            case .anonymous:
                promise.fail(
                    SMTPError(
                        "After user name executed for anonymous sign in method"
                    )
                )
                break
            }
        case .okAfterPassword:
            send(
                context: context,
                command: .mailFrom(email.from.address)
            )
            currentlyWaitingFor = .okAfterMailFrom
        case .okAfterMailFrom:
            if let recipient = recipients.popLast() {
                send(
                    context: context,
                    command: .recipient(recipient.address)
                )
            }
            else {
                fallthrough
            }
        case .okAfterRecipient:
            send(context: context, command: .data)
            currentlyWaitingFor = .okAfterDataCommand
        case .okAfterDataCommand:
            send(context: context, command: .transferData(email))
            currentlyWaitingFor = .okAfterMailData
        case .okAfterMailData:
            send(context: context, command: .quit)
            currentlyWaitingFor = .okAfterQuit
        case .okAfterQuit:
            promise.succeed(())
            currentlyWaitingFor = .nothing
        case .nothing:
            ()
        case .error:
            promise.fail(SMTPError("Communication error state"))
        }
    }
}
