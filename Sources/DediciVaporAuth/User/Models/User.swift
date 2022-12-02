//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Vapor

internal final class User: ResourceModel {
    static let schema = "users"

    @ID(key: FieldKeys.id)
    var id: UUID?

    @Field(key: FieldKeys.creationDate)
    var creationDate: Date

    @Field(key: FieldKeys.deletionDate)
    var deletionDate: Date?

    @Field(key: FieldKeys.disablingDate)
    var disablingDate: Date?

    @Field(key: FieldKeys.lastModificationDate)
    var lastModificationDate: Date

    @Field(key: FieldKeys.passwordHash)
    var passwordHash: String?

    @Field(key: FieldKeys.minimumAuthStepCount)
    var minimumAuthStepCount: Int

    init() {}

    init(
        id: IDValue? = nil,
        creationDate: Date = Date(),
        deletionDate: Date? = nil,
        disablingDate: Date? = nil,
        lastModificationDate: Date = Date(),
        passwordHash: String?,
        minimumAuthStepCount: Int = 2
    ) {
        self.id = id
        self.creationDate = creationDate
        self.deletionDate = deletionDate
        self.disablingDate = disablingDate
        self.lastModificationDate = lastModificationDate
        self.passwordHash = passwordHash
        self.minimumAuthStepCount = minimumAuthStepCount
    }
}

extension User {
    enum FieldKeys {
        static let id: FieldKey = .id
        static let creationDate: FieldKey = .string("creation_date")
        static let deletionDate: FieldKey = .string("deletion_date")
        static let disablingDate: FieldKey = .string("disabling_date")
        static let lastModificationDate: FieldKey = .string("last_modification_date")
        static let passwordHash: FieldKey = .string("passwordHash")
        static let minimumAuthStepCount: FieldKey = .string("minimumAuthStepCount")
    }
}

extension User: ModelCanBeDisabled {
    var disablingDateField: FieldProperty<User, Date?> { $disablingDate }
}

extension User: ModelCanBeDeleted {
    var deletionDateField: FieldProperty<User, Date?> { $deletionDate }

    func markAsDeleted() throws {
        guard deletionDate == nil else { return }

        let stringPlaceholder = "deleted:\(try id.require())"

        deletionDate = .init()
        passwordHash = stringPlaceholder
    }
}

extension User: HasDefaultResponse {
    typealias DefaultResponse = UserResponse
}
