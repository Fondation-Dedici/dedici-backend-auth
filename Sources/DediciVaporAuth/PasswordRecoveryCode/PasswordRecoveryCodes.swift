//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import Vapor

internal class PasswordRecoveryCodes {
    private let queue: DispatchQueue = .init(label: "PasswordRecoveryCodes")
    private var codes: [String: PasswordRecoveryCode] = [:]

    func findByCode(_ code: String) -> PasswordRecoveryCode? {
        queue.sync { codes[code] }
    }

    func findByUserId(_ userId: UUID) -> [PasswordRecoveryCode] {
        queue.sync { codes.values.filter { $0.userId == userId } }
    }

    func findByAuthMethodId(_ authMethodId: UUID) -> [PasswordRecoveryCode] {
        queue.sync { codes.values.filter { $0.authMethodId == authMethodId } }
    }

    func remove(code: String) {
        queue.sync { codes[code] = nil }
    }

    func clearForUserId(_ userId: UUID) {
        queue.sync { removeCodes(codes.values.filter { $0.userId == userId }) }
    }

    func clearForAuthMethodId(_ authMethodId: UUID) {
        queue.sync { removeCodes(codes.values.filter { $0.authMethodId == authMethodId }) }
    }

    func purgeExpired() {
        queue.sync { removeCodes(codes.values.filter(\.hasExpired)) }
    }

    func generateCode(for authMethodId: UUID, and userId: UUID) -> PasswordRecoveryCode {
        queue.sync {
            let existingCodes = Set(codes.values.filter { $0.userId == userId }.map(\.code))
            var codeString: String = Self.generateCode()
            while existingCodes.contains(codeString) {
                codeString = Self.generateCode()
            }
            let code = PasswordRecoveryCode(
                codeString,
                for: authMethodId,
                and: userId,
                expiringAt: Date().addingTimeInterval(PublicConfiguration.current.passwordRecoveryCodeMaxAge)
            )
            removeCodes(codes.values.filter { $0.authMethodId == authMethodId })
            codes[codeString] = code
            return code
        }
    }

    private func removeCodes<S: Sequence>(_ items: S) where S.Element == PasswordRecoveryCode {
        items.forEach { codes[$0.code] = nil }
    }

    private static func generateCode() -> String {
        Data(randomBytes: 6 * 6)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
}
