//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

struct PasswordValidationReport: Hashable, Content {
    enum Verification: String, CaseIterable, Hashable, Codable {
        case hasAtLeastOneLowercaseLetter
        case hasAtLeastOneUppercaseLetter
        case hasAtLeastOneNumber
        case hasAtLeastOnePunctuation
        case isLongEnough

        var isMandatory: Bool {
            switch self {
            case .isLongEnough: return true
            default: return false
            }
        }

        func validates(_ password: String, considering minimumLength: Int) -> Bool {
            switch self {
            case .hasAtLeastOneLowercaseLetter: return password.first(where: { $0.isLetter && $0.isLowercase }) != nil
            case .hasAtLeastOneUppercaseLetter: return password.first(where: { $0.isLetter && $0.isUppercase }) != nil
            case .hasAtLeastOneNumber: return password.first(where: { $0.isNumber }) != nil
            case .hasAtLeastOnePunctuation: return password.first(where: { $0.isPunctuation }) != nil
            case .isLongEnough: return password.count >= minimumLength
            }
        }
    }

    let allVerifications: Set<Verification>
    let mandatoryVerifications: Set<Verification>
    let requiredSuccessfulVerifications: Int
    let validatedVerifications: Set<Verification>
    let minimumLength: Int
    let isValid: Bool

    init(with password: String) {
        let allVerifications: Set<Verification> = Set(Verification.allCases)
        let mandatoryVerifications: Set<Verification> = Set(Verification.allCases.filter(\.isMandatory))
        let requiredSuccessfulVerifications = 4
        let minimumLength = 8
        let validatedVerifications: Set<Verification> = allVerifications
            .filter { $0.validates(password, considering: minimumLength) }
        let isValid = mandatoryVerifications.isSubset(of: validatedVerifications)
            && validatedVerifications.count >= requiredSuccessfulVerifications

        self.allVerifications = allVerifications
        self.mandatoryVerifications = mandatoryVerifications
        self.requiredSuccessfulVerifications = requiredSuccessfulVerifications
        self.validatedVerifications = validatedVerifications
        self.minimumLength = minimumLength
        self.isValid = isValid
    }
}
