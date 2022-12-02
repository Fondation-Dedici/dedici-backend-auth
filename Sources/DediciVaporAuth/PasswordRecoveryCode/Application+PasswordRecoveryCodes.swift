//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

extension Application {
    var passwordRecoveryCodes: PasswordRecoveryCodes {
        guard let codes = storage[PasswordRecoveryCodes.StorageKey.self] else {
            let codes = PasswordRecoveryCodes()
            storage[PasswordRecoveryCodes.StorageKey.self] = codes
            return codes
        }
        return codes
    }
}
