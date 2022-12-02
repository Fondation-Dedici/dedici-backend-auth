//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import Vapor

internal class AuthCodes {
    private let queue: DispatchQueue = .init(label: "AuthCodes")
    private var codes: [String: AuthCode] = [:]

    func findByCode(_ code: String) -> AuthCode? {
        queue.sync { codes[code] }
    }

    func findByUserId(_ userId: UUID) -> [AuthCode] {
        queue.sync { codes.values.filter { $0.userId == userId } }
    }

    func findByAuthMethodId(_ authMethodId: UUID) -> [AuthCode] {
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

    func generateCode(for authMethodId: UUID, and userId: UUID) -> AuthCode {
        queue.sync {
            let existingCodes = Set(codes.values.filter { $0.userId == userId }.map(\.code))
            var codeString: String = Self.generateCode()
            while existingCodes.contains(codeString) {
                codeString = Self.generateCode()
            }
            let code = AuthCode(
                codeString,
                for: authMethodId,
                and: userId,
                expiringAt: Date().addingTimeInterval(PublicConfiguration.current.authCodeMaxAge)
            )
            removeCodes(codes.values.filter { $0.authMethodId == authMethodId })
            codes[codeString] = code
            return code
        }
    }

    private func removeCodes<S: Sequence>(_ items: S) where S.Element == AuthCode {
        items.forEach { codes[$0.code] = nil }
    }

    private static func generateCode() -> String {
        Data(randomBytes: 6)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
}
