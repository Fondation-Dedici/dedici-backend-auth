//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import Fluent
import Foundation
import Vapor

internal typealias AuthStepsRepository = DefaultRepository<AuthStep>

extension AuthStepsRepository {
    func steps(for sessionId: Session.IDValue) -> EventLoopFuture<[AuthStep]> {
        AuthStep.query(on: database)
            .filter(\.$sessionId == sessionId)
            .all()
    }

    func stepsCount(for sessionId: Session.IDValue) -> EventLoopFuture<Int> {
        AuthStep.query(on: database)
            .filter(\.$sessionId == sessionId)
            .count()
    }
}
