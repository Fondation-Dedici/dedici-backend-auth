//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

internal struct EmailEmailCheckCode: EmailBody {
    static var templateId: String { "fr.email_check_code.code" }

    let code: String
}
