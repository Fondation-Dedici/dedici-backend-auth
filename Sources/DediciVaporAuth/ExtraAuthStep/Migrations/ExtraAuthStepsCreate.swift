//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Fluent

internal struct ExtraAuthStepsCreate: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ExtraAuthStep.schema)
            .id()
            .field(ExtraAuthStep.FieldKeys.creationDate, .datetime, .required)
            .field(ExtraAuthStep.FieldKeys.lastModificationDate, .datetime, .required)
            .field(ExtraAuthStep.FieldKeys.sessionId, .uuid, .required)
            .field(ExtraAuthStep.FieldKeys.key, .string, .required)
            .field(ExtraAuthStep.FieldKeys.payload, .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ExtraAuthStep.schema)
            .delete()
    }
}
