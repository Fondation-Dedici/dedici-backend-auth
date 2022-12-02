//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Vapor

internal final class AuthMethod: ResourceModel {
    static let schema = "auth_methods"

    @ID(key: FieldKeys.id)
    var id: UUID?

    @Field(key: FieldKeys.creationDate)
    var creationDate: Date

    @Field(key: FieldKeys.lastModificationDate)
    var lastModificationDate: Date

    @Field(key: FieldKeys.userId)
    var userId: UUID

    @Field(key: FieldKeys.verificationDate)
    var verificationDate: Date?

    @Field(key: FieldKeys.value)
    var value: String

    @Field(key: FieldKeys.type)
    var type: AuthMethodType

    init() {}

    init(
        id: UUID,
        userId: UUID,
        value: String,
        type: AuthMethodType,
        hasAlreadyBeenVerified: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.value = value
        self.type = type
        self.verificationDate = hasAlreadyBeenVerified ? .init() : nil
    }
}

extension AuthMethod {
    enum FieldKeys {
        static let id: FieldKey = .id
        static let creationDate: FieldKey = .string("creation_date")
        static let lastModificationDate: FieldKey = .string("last_modification_date")
        static let userId: FieldKey = .string("user_id")
        static let verificationDate: FieldKey = .string("verification_date")
        static let value: FieldKey = .string("value")
        static let type: FieldKey = .string("type")
    }
}
