//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

extension PasswordRecoveryCodes {
    struct StorageKey: Vapor.StorageKey {
        typealias Value = PasswordRecoveryCodes
    }
}
