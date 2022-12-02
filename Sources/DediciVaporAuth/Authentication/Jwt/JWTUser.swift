//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import JWT
import Vapor

internal struct JWTUser: JWTPayload, Equatable {
    enum ArgumentError: Error {
        case userIdIsNil(user: User)
    }

    let iat: IssuedAtClaim
    let exp: ExpirationClaim
    let userId: UUIDv4
    let sessionId: UUIDv4
    let subaccounts: [UUIDv4]?
    let extraAuth: JsonObject?

    init(
        authResult _: SessionAuthResult,
        userId: UUIDv4,
        sessionId: UUIDv4,
        subaccounts: [UUIDv4],
        extraAuthSteps: [ExtraAuthStep],
        now: Date = .init(),
        duration: TimeInterval = PublicConfiguration.current.jwtMaxAge
    ) throws {
        self.exp = .init(value: now.addingTimeInterval(duration))
        self.iat = .init(value: now)
        self.userId = userId
        self.sessionId = sessionId
        self.subaccounts = subaccounts.isEmpty ? nil : subaccounts
        if extraAuthSteps.isEmpty {
            self.extraAuth = nil
        } else {
            let decoder = JSONDecoder()
            self.extraAuth = try extraAuthSteps.reduce(into: [:]) {
                $0[$1.key] = try $1.payload
                    .data(using: .utf8)
                    .flatMap { try decoder.decode(JsonValue.self, from: $0) }
            }
        }
    }

    func verify(using _: JWTSigner) throws {
        try exp.verifyNotExpired()
    }
}
