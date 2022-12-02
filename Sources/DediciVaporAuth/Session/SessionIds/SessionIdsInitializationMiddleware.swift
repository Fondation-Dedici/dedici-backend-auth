//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

internal struct SessionIdsInitializationMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        if !request.application.sessionIds.initialized {
            return request.application.sessionIds
                .intialize(for: request.application)
                .flatMap { next.respond(to: request) }
        } else {
            return next.respond(to: request)
        }
    }
}
