//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct AuthMethodShortResponse: Content {
    var methodId: UUIDv4
    var methodValuePreview: String?
    var methodType: AuthMethodType
    var stepTypes: Set<AuthStepType>
}
