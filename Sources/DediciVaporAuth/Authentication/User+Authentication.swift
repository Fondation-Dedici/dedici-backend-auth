//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

extension User {
    func nilIfCannotAuthenticate() -> User? {
        guard !hasBeenDeleted else { return nil }
        guard !hasBeenDisabled else { return nil }
        return self
    }
}
