//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

internal struct EmailCheckCodesExpirationMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        request.application.emailCheckCodes.purgeExpired()
        return next.respond(to: request)
    }
}
