//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Fluent

internal struct UsersCreate: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema)
            .id()
            .field(User.FieldKeys.creationDate, .datetime, .required)
            .field(User.FieldKeys.lastModificationDate, .datetime, .required)
            .field(User.FieldKeys.deletionDate, .datetime)
            .field(User.FieldKeys.disablingDate, .datetime)
            .field(User.FieldKeys.passwordHash, .string)
            .field(User.FieldKeys.minimumAuthStepCount, .int, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema)
            .delete()
    }
}
