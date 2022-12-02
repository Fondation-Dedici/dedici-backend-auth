//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import Vapor

internal struct PasswordRecoveryCode: Content, CanExpire {
    let code: String
    let authMethodId: UUID
    let userId: UUID
    var expirationDate: Date?

    init(_ code: String, for methodId: UUID, and userId: UUID, expiringAt expirationDate: Date) {
        self.code = code
        self.authMethodId = methodId
        self.userId = userId
        self.expirationDate = expirationDate
    }
}
