//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Fluent

internal struct AuthMethodsCreate: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(AuthMethod.schema)
            .id()
            .field(AuthMethod.FieldKeys.creationDate, .datetime, .required)
            .field(AuthMethod.FieldKeys.lastModificationDate, .datetime, .required)
            .field(AuthMethod.FieldKeys.userId, .uuid, .required)
            .field(AuthMethod.FieldKeys.verificationDate, .datetime)
            .field(AuthMethod.FieldKeys.value, .string, .required)
            .field(AuthMethod.FieldKeys.type, .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(AuthMethod.schema)
            .delete()
    }
}
