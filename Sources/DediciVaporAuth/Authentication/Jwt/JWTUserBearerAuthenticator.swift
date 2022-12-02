//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import JWT
import Vapor

internal struct JWTUserBearerAuthenticator {}

extension JWTUserBearerAuthenticator: BearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) -> EventLoopFuture<Void> {
        guard let jwt = try? request.jwt.verify(bearer.token, as: JWTUser.self) else {
            return request.eventLoop.makeSucceededFuture(())
        }

        return UsersRepository(database: request.db).find(jwt.userId.value)
            .map { $0?.nilIfCannotAuthenticate() }
            .map {
                $0.flatMap {
                    request.auth.login(UserAuthResult(userId: jwt.userId, user: $0, extraAuth: jwt.extraAuth))
                }
            }
    }
}
