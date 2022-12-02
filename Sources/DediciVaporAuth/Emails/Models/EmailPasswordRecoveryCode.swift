//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

internal struct EmailPasswordRecoveryCode: EmailBody {
    static var templateId: String { "fr.password_recovery.code" }

    let code: String
}
