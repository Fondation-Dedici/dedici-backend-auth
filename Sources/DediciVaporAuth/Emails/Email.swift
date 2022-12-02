//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

internal struct Email<Body: EmailBody>: Encodable {
    internal enum CodingKeys: String, CodingKey {
        case body = "params"
        case subject
        case recipient = "to"
        case templateId
    }

    let body: Body
    let subject: String
    let recipient: String
    let templateId: String

    init(body: Body, subject: String, recipient: String) {
        self.body = body
        self.subject = subject
        self.recipient = recipient
        self.templateId = Body.templateId
    }
}
