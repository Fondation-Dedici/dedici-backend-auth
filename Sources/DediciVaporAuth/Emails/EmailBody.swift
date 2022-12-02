//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

protocol EmailBody: Encodable {
    static var templateId: String { get }
}
