//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Fluent

internal struct AuthStepsCreate: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(AuthStep.schema)
            .id()
            .field(AuthStep.FieldKeys.creationDate, .datetime, .required)
            .field(AuthStep.FieldKeys.lastModificationDate, .datetime, .required)
            .field(AuthStep.FieldKeys.sessionId, .uuid, .required)
            .field(AuthStep.FieldKeys.type, .string, .required)
            .field(AuthStep.FieldKeys.authMethodId, .uuid, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(AuthStep.schema)
            .delete()
    }
}
