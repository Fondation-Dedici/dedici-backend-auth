//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

extension Application {
    var emailCheckCodes: EmailCheckCodes {
        guard let codes = storage[EmailCheckCodes.StorageKey.self] else {
            let codes = EmailCheckCodes()
            storage[EmailCheckCodes.StorageKey.self] = codes
            return codes
        }
        return codes
    }
}
