//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Foundation
import Vapor

internal struct SessionResponse: ResourceRequestResponse {
    var id: UUIDv4
    var creationDate: Date
    var lastModificationDate: Date
    var expirationDate: Date?
    var userId: UUIDv4
    var token: Data
    var authSteps: [AuthStepResponse]
    var extraAuthSteps: [ExtraAuthStepResponse]
    var minimumAuthStepCount: Int

    static func make(from resource: Session, and request: Request) throws -> EventLoopFuture<Self> {
        try make(from: resource, and: request, on: request.db)
    }

    static func make(
        from resource: Session,
        and request: Request,
        on database: Database?
    ) throws -> EventLoopFuture<Self> {
        let database = database ?? request.db
        let sessionId = try UUIDv4(value: resource.id.require())
        let authSteps = AuthStepsRepository(database: database).steps(for: sessionId.value)
        let extraAuthSteps = ExtraAuthStepsRepository(database: database).steps(for: sessionId.value)

        return authSteps.and(extraAuthSteps).flatMapThrowing { steps, extraSteps in
            Self(
                id: sessionId,
                creationDate: resource.creationDate,
                lastModificationDate: resource.lastModificationDate,
                expirationDate: resource.expirationDate,
                userId: try .init(value: resource.userId),
                token: resource.token,
                authSteps: try steps.map { try AuthStepResponse(from: $0, and: request) },
                extraAuthSteps: try extraSteps.map { try ExtraAuthStepResponse(from: $0, and: request) },
                minimumAuthStepCount: resource.minimumAuthStepCount
            )
        }
    }
}
