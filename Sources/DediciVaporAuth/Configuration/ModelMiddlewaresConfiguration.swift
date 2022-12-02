//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Foundation
import Vapor

internal struct ModelMiddlewaresConfiguration: AppConfiguration {
    func configure(_ application: Application) throws {
        let middlewares: [AnyModelMiddleware] = [
            ResourceModelMiddleware<User>(),
            ResourceModelMiddleware<Session>(),
            ResourceModelMiddleware<AuthStep>(),
            ResourceModelMiddleware<ExtraAuthStep>(),
            ResourceModelMiddleware<AuthMethod>(),
            SessionIdsModelMiddleware(application: application),
        ]

        middlewares.forEach { application.databases.middleware.use($0) }
    }
}
