//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Foundation
import Vapor

internal struct MigrationsConfiguration: AppConfiguration {
    func configure(_ application: Application) throws {
        let migrations: [Migration] = [
            UsersCreate(),
            SessionsCreate(),
            AuthStepsCreate(),
            ExtraAuthStepsCreate(),
            AuthMethodsCreate(),
        ]

        migrations.forEach { application.migrations.add($0) }
    }
}
