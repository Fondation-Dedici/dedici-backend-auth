//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import JWT
import Vapor

extension Application {
    public func configure() throws {
        try apply(MiddlewaresConfiguration())
            .apply(DatabaseConfiguration())
            .apply(ModelMiddlewaresConfiguration())
            .apply(MigrationsConfiguration())
            .apply(RoutesConfiguration())
            .apply(JwtConfiguration())
            .apply(ContentConfiguration())
    }
}
