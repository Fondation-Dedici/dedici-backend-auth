//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import Vapor

internal class SessionIds {
    private var queue: DispatchQueue = .init(label: "SessionIds")
    private(set) var ids: Set<Session.IDValue> = []
    private(set) var initialized: Bool = false

    func contains(_ sessionId: Session.IDValue) -> Bool {
        queue.sync { ids.contains(sessionId) }
    }

    func add(_ sessionId: Session.IDValue) {
        _ = queue.sync { ids.insert(sessionId) }
    }

    func remove(_ sessionId: Session.IDValue) {
        _ = queue.sync { ids.remove(sessionId) }
    }

    func intialize(for application: Application) -> EventLoopFuture<Void> {
        let initialized = queue.sync { self.initialized }
        guard !initialized else { return application.eventLoopGroup.future() }
        return Session.query(on: application.db).all(\.$id)
            .map { self.ids = Set($0) }
            .map { self.initialized = true }
    }
}
