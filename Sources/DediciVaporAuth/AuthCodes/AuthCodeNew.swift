//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import Vapor

internal struct AuthCodeNew: Content {
    let authMethodId: UUIDv4
}
