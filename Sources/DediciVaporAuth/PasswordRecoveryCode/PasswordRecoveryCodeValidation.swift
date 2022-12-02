//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

internal struct PasswordRecoveryCodeValidation: Content {
    let code: String
    let newPassword: NewPassword
}
