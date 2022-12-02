//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Fluent

internal struct SessionsCreate: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Session.schema)
            .id()
            .field(Session.FieldKeys.creationDate, .datetime, .required)
            .field(Session.FieldKeys.lastModificationDate, .datetime, .required)
            .field(Session.FieldKeys.expirationDate, .datetime)
            .field(Session.FieldKeys.userId, .uuid, .required)
            .field(Session.FieldKeys.token, .data, .required)
            .field(Session.FieldKeys.minimumAuthStepCount, .int, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Session.schema)
            .delete()
    }
}
