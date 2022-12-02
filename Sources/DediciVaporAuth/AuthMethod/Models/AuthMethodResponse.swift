//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct AuthMethodResponse: ResourceRequestResponse {
    var id: UUIDv4
    var creationDate: Date
    var lastModificationDate: Date?
    var userId: UUID
    var verificationDate: Date?
    var value: String
    var type: AuthMethodType

    static func make(from resource: AuthMethod, and request: Request) throws -> EventLoopFuture<Self> {
        let response = try Self(from: resource, and: request)
        return request.eventLoop.makeSucceededFuture(response)
    }

    init(from resource: AuthMethod, and _: Request) throws {
        self.id = try .init(value: resource.id.require())
        self.creationDate = resource.creationDate
        self.lastModificationDate = resource.lastModificationDate
        self.userId = resource.userId
        self.verificationDate = resource.verificationDate
        self.value = resource.value
        self.type = resource.type
    }
}
