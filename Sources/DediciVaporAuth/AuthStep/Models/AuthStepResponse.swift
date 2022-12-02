//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct AuthStepResponse: ResourceRequestResponse {
    var id: UUIDv4
    var creationDate: Date
    var lastModificationDate: Date?
    var sessionId: UUID
    var type: AuthStepType
    var authMethodId: UUID

    static func make(from resource: AuthStep, and request: Request) throws -> EventLoopFuture<Self> {
        let response = try Self(from: resource, and: request)
        return request.eventLoop.makeSucceededFuture(response)
    }

    init(from resource: AuthStep, and _: Request) throws {
        self.id = try .init(value: resource.id.require())
        self.creationDate = resource.creationDate
        self.lastModificationDate = resource.lastModificationDate
        self.sessionId = resource.sessionId
        self.authMethodId = resource.authMethodId
        self.type = resource.type
    }
}
