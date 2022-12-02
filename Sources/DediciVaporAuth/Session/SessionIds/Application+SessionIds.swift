//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

extension Application {
    var sessionIds: SessionIds {
        guard let ids = storage[SessionIds.StorageKey.self] else {
            let ids = SessionIds()
            storage[SessionIds.StorageKey.self] = ids
            return ids
        }
        return ids
    }
}
