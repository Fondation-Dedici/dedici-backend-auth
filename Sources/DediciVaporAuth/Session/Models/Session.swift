//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Vapor

internal final class Session: ResourceModel {
    static let schema = "sessions"

    @ID(key: FieldKeys.id)
    var id: UUID?

    @Field(key: FieldKeys.creationDate)
    var creationDate: Date

    @Field(key: FieldKeys.lastModificationDate)
    var lastModificationDate: Date

    @Field(key: FieldKeys.userId)
    var userId: UUID

    @Field(key: FieldKeys.token)
    var token: Data

    @Field(key: FieldKeys.expirationDate)
    var expirationDate: Date?

    @Field(key: FieldKeys.minimumAuthStepCount)
    var minimumAuthStepCount: Int

    init() {}

    init(
        id: UUID,
        userId: UUID,
        maxAge: Int? = nil,
        minimumAuthStepCount: Int
    ) {
        self.id = id
        self.userId = userId
        self.token = Data(randomBytes: 512)
        self.expirationDate = maxAge
            .flatMap(TimeInterval.init)
            .flatMap(Date().addingTimeInterval)
        self.minimumAuthStepCount = minimumAuthStepCount
    }
}

extension Session {
    enum FieldKeys {
        static let id: FieldKey = .id
        static let creationDate: FieldKey = .string("creation_date")
        static let lastModificationDate: FieldKey = .string("last_modification_date")
        static let expirationDate: FieldKey = .string("expiration_date")
        static let token: FieldKey = .string("token")
        static let userId: FieldKey = .string("user_id")
        static let minimumAuthStepCount: FieldKey = .string("minimumAuthStepCount")
    }
}

extension Session: HasDefaultResponse {
    typealias DefaultResponse = SessionResponse
}

extension Session: HasDefaultCreateOneBody {
    typealias DefaultCreateOneBody = SessionNew
}

extension Session: ModelCanExpire {
    var expirationDateField: FieldProperty<Session, Date?> { $expirationDate }
}
