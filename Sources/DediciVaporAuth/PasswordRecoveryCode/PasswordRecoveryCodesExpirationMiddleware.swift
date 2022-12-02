//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

internal struct PasswordRecoveryCodesExpirationMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        request.application.passwordRecoveryCodes.purgeExpired()
        return next.respond(to: request)
    }
}
