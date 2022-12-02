//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

public struct PublicConfiguration: Codable {
    public static let current: PublicConfiguration = {
        do {
            let authCodeMaxAge = try Environment.require(
                key: "AUTH_CODE_MAX_AGE",
                using: TimeInterval.init
            )
            let emailCheckCodeMaxAge = try Environment.require(
                key: "EMAIL_CHECK_CODE_MAX_AGE",
                using: TimeInterval.init
            )
            let passwordRecoveryCodeMaxAge = try Environment.require(
                key: "PASSWORD_RECOVERY_CODE_MAX_AGE",
                using: TimeInterval.init
            )
            let requiredExtraAuthSteps = try ExtraAuth.requiredExtraAuthKeys()
            let jwtMaxAge = try Environment.require(
                key: "AUTH_JWT_MAX_AGE",
                using: TimeInterval.init
            )

            return PublicConfiguration(
                authCodeMaxAge: authCodeMaxAge,
                emailCheckCodeMaxAge: emailCheckCodeMaxAge,
                passwordRecoveryCodeMaxAge: passwordRecoveryCodeMaxAge,
                requiredExtraAuthSteps: requiredExtraAuthSteps,
                jwtMaxAge: jwtMaxAge
            )

        } catch {
            fatalError("Failed to load configuration because: \(error)")
        }
    }()

    public let authCodeMaxAge: TimeInterval
    public let emailCheckCodeMaxAge: TimeInterval
    public let passwordRecoveryCodeMaxAge: TimeInterval
    public let requiredExtraAuthSteps: Set<String>
    public let jwtMaxAge: TimeInterval
}
