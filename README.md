# Feather Mail Component

A mail component, which can send emails using via [AWS SES](https://aws.amazon.com/ses/) or [SMTP](https://hu.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol) providers.

## Getting started 

Adding the dependency

Add the following entry in your Package.swift to start using `FeatherMail`:

```swift
.package(url: "https://github.com/feathercms/feather-mail", from: "1.0.0"),
```

and the `FeatherMail` dependency to your target:

```swift
.product(name: "FeatherMail", package: "feather-mail"),
```

Mail provider services

```swift
# SMTP
.product(name: "FeatherSMTPMail", package: "feather-mail"),

# SES
.product(name: "FeatherSESMail", package: "feather-mail"),
```    

## FeatherSESMail

Simple usage

```swift
import Feather
import FeatherMail
import FeatherSESMail

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
```

## FeatherSMTPMail

Simple usage

```swift
import Feather
import FeatherMail
import FeatherSMTPMail

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
```

## Credits 

The NIOSMTP library is heavily inspired by [Mikroservices/Smtp](https://github.com/Mikroservices/Smtp).
