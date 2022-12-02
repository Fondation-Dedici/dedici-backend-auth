//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import Fluent
import Foundation
import Vapor

internal typealias ExtraAuthStepsRepository = DefaultRepository<ExtraAuthStep>

extension ExtraAuthStepsRepository {
    func steps(for sessionId: Session.IDValue) -> EventLoopFuture<[ExtraAuthStep]> {
        ExtraAuthStep.query(on: database)
            .filter(\.$sessionId == sessionId)
            .all()
    }
}
