//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct UserResponse: ResourceRequestResponse {
    var id: UUIDv4
    var creationDate: Date
    var lastModificationDate: Date
    var deletionDate: Date?
    var disablingDate: Date?
    var authMethods: [AuthMethodResponse]
    var minimumAuthStepCount: Int

    static func make(from resource: User, and request: Request) throws -> EventLoopFuture<Self> {
        let userId = try UUIDv4(value: resource.id.require())

        return AuthMethodsRepository(database: request.db).methods(for: userId.value)
            .flatMapThrowing { methods in
                Self(
                    id: userId,
                    creationDate: resource.creationDate,
                    lastModificationDate: resource.lastModificationDate,
                    deletionDate: resource.deletionDate,
                    disablingDate: resource.disablingDate,
                    authMethods: try methods.map { try AuthMethodResponse(from: $0, and: request) },
                    minimumAuthStepCount: resource.minimumAuthStepCount
                )
            }
    }
}
