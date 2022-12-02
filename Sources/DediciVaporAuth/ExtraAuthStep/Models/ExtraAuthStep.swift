//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Vapor

internal final class ExtraAuthStep: ResourceModel {
    static let schema = "session_extra_auth_steps"

    @ID(key: FieldKeys.id)
    var id: UUID?

    @Field(key: FieldKeys.creationDate)
    var creationDate: Date

    @Field(key: FieldKeys.lastModificationDate)
    var lastModificationDate: Date

    @Field(key: FieldKeys.sessionId)
    var sessionId: UUID

    @Field(key: FieldKeys.key)
    var key: String

    @Field(key: FieldKeys.payload)
    var payload: String

    init() {}

    init(
        id: UUID,
        sessionId: UUID,
        key: String,
        payload: JsonValue
    ) throws {
        self.id = id
        self.sessionId = sessionId
        self.key = key
        let encoder = JSONEncoder()
        self.payload = try encoder.encode(payload).decodeString() ?? ""
    }
}

extension ExtraAuthStep {
    enum FieldKeys {
        static let id: FieldKey = .id
        static let creationDate: FieldKey = .string("creation_date")
        static let lastModificationDate: FieldKey = .string("last_modification_date")
        static let sessionId: FieldKey = .string("session_id")
        static let key: FieldKey = .string("key")
        static let payload: FieldKey = .string("payload")
    }
}
