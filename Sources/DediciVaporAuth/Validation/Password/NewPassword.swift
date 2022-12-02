//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import Vapor

internal struct NewPassword: SanitizedValue {
    let value: String
    let validationReport: PasswordValidationReport

    init(sanitizing rawValue: String) throws {
        let password = rawValue
        let report = PasswordValidationReport(with: password)
        guard report.isValid else { throw SpecificError.invalidPassword(report: report) }
        self.value = password
        self.validationReport = report
    }

    func hashed(using hasher: (_ password: String) throws -> String) throws -> String {
        try hasher(value)
    }
}
