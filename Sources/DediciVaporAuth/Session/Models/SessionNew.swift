//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct SessionNew {
    var email: String
    var password: String
    var maxAge: NewMaxAge?
}

extension SessionNew: ResourceCreateOneRequestBody {
    typealias Resource = Session

    func asResource(considering request: Request) throws -> EventLoopFuture<Session> {
        let body = try request.content.decode(SessionNew.self)
        return request.repositories.get(for: SessionsRepository.self)
            .creatingSession(from: body, using: request.password.verify)
    }
}
