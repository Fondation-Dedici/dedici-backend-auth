//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Vapor

internal final class AuthStep: ResourceModel {
    static let schema = "session_auth_steps"

    @ID(key: FieldKeys.id)
    var id: UUID?

    @Field(key: FieldKeys.creationDate)
    var creationDate: Date

    @Field(key: FieldKeys.lastModificationDate)
    var lastModificationDate: Date

    @Field(key: FieldKeys.sessionId)
    var sessionId: Session.IDValue

    @Field(key: FieldKeys.type)
    var type: AuthStepType

    @Field(key: FieldKeys.authMethodId)
    var authMethodId: AuthMethod.IDValue

    init() {}

    init(
        id: UUID? = nil,
        sessionId: UUID,
        type: AuthStepType,
        authMethodId: UUID
    ) {
        self.id = id ?? .init()
        self.sessionId = sessionId
        self.type = type
        self.authMethodId = authMethodId
    }
}

extension AuthStep {
    enum FieldKeys {
        static let id: FieldKey = .id
        static let creationDate: FieldKey = .string("creation_date")
        static let lastModificationDate: FieldKey = .string("last_modification_date")
        static let sessionId: FieldKey = .string("session_id")
        static let type: FieldKey = .string("type")
        static let authMethodId: FieldKey = .string("auth_method_id")
    }
}
