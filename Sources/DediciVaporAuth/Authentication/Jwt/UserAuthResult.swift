//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import Vapor

internal struct UserAuthResult: Authenticatable, Content {
    let userId: UUIDv4
    let user: User
    let extraAuth: JsonObject?
}
