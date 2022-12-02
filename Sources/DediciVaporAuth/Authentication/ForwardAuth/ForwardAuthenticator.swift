//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import JWT
import Vapor

internal struct ForwardAuthenticator {}

extension ForwardAuthenticator: BearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) -> EventLoopFuture<Void> {
        guard let jwt = try? request.jwt.verify(bearer.token, as: JWTUser.self) else {
            return request.eventLoop.makeSucceededFuture(())
        }

        guard request.application.sessionIds.contains(jwt.sessionId.value) else {
            return request.eventLoop.future(error: Abort(.forbidden))
        }

        let result = ServerAuthResult(
            userId: jwt.userId,
            sessionId: jwt.sessionId,
            subaccounts: jwt.subaccounts,
            extraAuth: jwt.extraAuth
        )
        request.auth.login(result)
        return request.eventLoop.future()
    }
}
