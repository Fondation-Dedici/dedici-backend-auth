//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporAuth
import DediciVaporFluentToolbox
import DediciVaporToolbox
import Vapor

internal var env = try Environment.detect()
internal let app = Application(env)

// Setting up the logging system is kind of tricky for now. See: https://github.com/vapor/vapor/issues/2429
try LoggingSystem.bootstrap(from: &env)
app.logger = .init(label: app.logger.label)

internal let isDummy = (try? Environment.require(key: "DATABASE_IS_IN_MEMORY", using: { Bool($0) })) ?? false

defer { app.shutdown() }

let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .OPTIONS, .PATCH],
    allowedHeaders: [
        .accept,
        .authorization,
        .contentType,
        .origin,
        .xRequestedWith,
        .userAgent,
        .accessControlAllowOrigin,
        .nxErrorCode,
        .nxServerTimeStart,
        .nxServerTimeEnd,
        .nxVersion,
        .nxVersionStatus,
        .nxVersionCurrent,
        .nxVersionDeprecated,
        .nxVersionMinimum,
    ]
)
let cors = CORSMiddleware(configuration: corsConfiguration)
let timing = TimingMiddleware()
let error = ErrorMiddleware.default(environment: app.environment)
let logging = RouteLoggingMiddleware(logLevel: .info)
// Clear any existing middleware.
app.middleware = .init()
app.middleware.use(logging)
app.middleware.use(timing)
app.middleware.use(cors)
app.middleware.use(error)

try app.configure()

try app.autoMigrateUntilSuccess().wait()
if app.environment.name != "xcode" {
    try app.publishConfigUntilSuccess(config: PublicConfiguration.current, key: "auth-api").wait()
}

try app.run()
