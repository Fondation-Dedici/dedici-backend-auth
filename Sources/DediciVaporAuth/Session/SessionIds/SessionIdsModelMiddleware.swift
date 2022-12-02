//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Fluent
import Foundation
import Vapor

internal struct SessionIdsModelMiddleware: ModelMiddleware {
    typealias Model = Session

    var application: Application

    func handle(
        _ event: ModelEvent,
        _ model: AnyModel,
        on db: Database,
        chainingTo next: AnyModelResponder
    ) -> EventLoopFuture<Void> {
        if let session = model as? Session, let id = session.id {
            switch event {
            case .create, .restore:
                application.sessionIds.add(id)
            case .delete, .softDelete:
                application.sessionIds.remove(id)
            case .update: break
            }
        }
        return next.handle(event, model, on: db)
    }
}
