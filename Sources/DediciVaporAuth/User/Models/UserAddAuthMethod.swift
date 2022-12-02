//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import Vapor

internal struct UserAddAuthMethod: Content {
    let id: UUIDv4?
    let type: AuthMethodType
    let value: String
}
