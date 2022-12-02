//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

internal struct EmailAuthCode: EmailBody {
    static var templateId: String { "fr.auth_code.code" }

    let code: String
}
