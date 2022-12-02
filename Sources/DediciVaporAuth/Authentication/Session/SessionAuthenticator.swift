//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import JWT
import Vapor

internal struct SessionAuthenticator {}

extension SessionAuthenticator: BearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) -> EventLoopFuture<Void> {
        guard let token = Data(base64Encoded: bearer.token) else { return request.eventLoop.future() }

        return SessionsRepository(database: request.db).findByToken(token: token)
            .optionalFlatMapThrowing { SessionAuthResult(sessionId: try .init(value: $0.id.require()), session: $0) }
            .optionalMap { request.auth.login($0) }
            .map { _ in }
    }
}
