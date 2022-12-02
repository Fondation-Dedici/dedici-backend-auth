//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import Vapor

internal struct NewMaxAge: SanitizedValue {
    let value: Int

    init(sanitizing rawValue: Int) throws {
        let minimum = 0
        let maximum = Int.max
        guard (minimum ... maximum).contains(rawValue) else {
            throw Abort(
                .badRequest,
                reason: "The value must be equal or greater than "
                    + "\(minimum) and equal or lower than \(maximum)"
            )
        }
        self.value = rawValue
    }
}
