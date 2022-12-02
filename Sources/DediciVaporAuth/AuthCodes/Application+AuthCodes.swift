//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

extension Application {
    var authCodes: AuthCodes {
        guard let codes = storage[AuthCodes.StorageKey.self] else {
            let codes = AuthCodes()
            storage[AuthCodes.StorageKey.self] = codes
            return codes
        }
        return codes
    }
}
