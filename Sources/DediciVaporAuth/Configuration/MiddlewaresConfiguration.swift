//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct MiddlewaresConfiguration: AppConfiguration {
    func configure(_ application: Application) throws {
        let middlewares: [Middleware] = [
            SpecificErrorMiddleware(),
            VersionMiddleware(),
            ResourceDeleteExpiredMiddleware<Session>(),
            SessionIdsInitializationMiddleware(),
            AuthCodesExpirationMiddleware(),
            PasswordRecoveryCodesExpirationMiddleware(),
        ]

        middlewares.forEach { application.middleware.use($0) }
    }
}
