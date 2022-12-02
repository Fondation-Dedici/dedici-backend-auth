//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct ExtraAuthStepResponse: ResourceRequestResponse {
    var id: UUIDv4
    var creationDate: Date
    var lastModificationDate: Date?
    var sessionId: UUID
    var key: String
    var payload: JsonValue?

    static func make(from resource: ExtraAuthStep, and request: Request) throws -> EventLoopFuture<Self> {
        let response = try Self(from: resource, and: request)
        return request.eventLoop.makeSucceededFuture(response)
    }

    init(from resource: ExtraAuthStep, and _: Request) throws {
        self.id = try .init(value: resource.id.require())
        self.creationDate = resource.creationDate
        self.lastModificationDate = resource.lastModificationDate
        self.sessionId = resource.sessionId
        self.key = resource.key
        guard let payloadData = resource.payload.data(using: .utf8) else {
            throw Abort(.internalServerError, reason: "Payload is not valid UTF-8")
        }
        let decoder = JSONDecoder()
        do {
            self.payload = try decoder.decode(JsonValue.self, from: payloadData)
        } catch {
            throw Abort(.internalServerError, reason: "Failed to decode payload data because: \(error)")
        }
    }
}
