//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import Vapor

internal enum SpecificError: DediciVaporToolbox.SpecificError {
    case emailAddressAlreadyAssociated
    case emailAddressAlreadyVerified
    case invalidEmailAddress
    case invalidPassword(report: PasswordValidationReport)

    var rawValue: String {
        switch self {
        case .emailAddressAlreadyAssociated: return "emailAddressAlreadyAssociated"
        case .emailAddressAlreadyVerified: return "emailAddressAlreadyVerified"
        case .invalidEmailAddress: return "invalidEmailAddress"
        case .invalidPassword: return "invalidPassword"
        }
    }

    func body() throws -> Response.Body {
        switch self {
        case .invalidPassword(let report):
            return .init(data: try ContentConfiguration.jsonEncoder.encode(report))
        default: return .empty
        }
    }
}
