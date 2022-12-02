//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import Fluent
import Foundation
import Vapor

internal typealias AuthMethodsRepository = DefaultRepository<AuthMethod>

extension AuthMethodsRepository {
    func methods(for userId: User.IDValue, from database: Database? = nil) -> EventLoopFuture<[AuthMethod]> {
        AuthMethod.query(on: database ?? self.database)
            .filter(\.$userId == userId)
            .all()
    }

    func methods(for value: String, from database: Database? = nil) -> EventLoopFuture<[AuthMethod]> {
        AuthMethod.query(on: database ?? self.database)
            .filter(\.$value == value)
            .all()
    }
}
