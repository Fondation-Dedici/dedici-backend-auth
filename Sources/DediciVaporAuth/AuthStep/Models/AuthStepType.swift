//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

internal enum AuthStepType: String, Content, Hashable {
    case password
    case ephemeralCode
    case parentUser
}
