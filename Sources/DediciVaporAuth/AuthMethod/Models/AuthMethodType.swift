//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import Vapor

internal enum AuthMethodType: String, Hashable, Codable {
    enum StepsCapacity {
        case bypass
        case value(Int)

        var isBypass: Bool {
            switch self {
            case .bypass: return true
            default: return false
            }
        }

        var value: Int? {
            switch self {
            case .value(let value): return value
            default: return nil
            }
        }
    }

    case emailAddress
    case parentUserId

    func preview(from value: String) -> String? {
        switch self {
        case .emailAddress:
            let firstPartRaw = value.split(separator: "@").first
            let firstPart = firstPartRaw?.prefix(min(4, (firstPartRaw?.count ?? 0) / 2))
            let lastPart = value.split(separator: "@").last?.split(separator: ".").last.flatMap { ".\($0)" }
            return [
                firstPart.flatMap { "\($0)" },
                " … @ … ",
                lastPart,
            ]
            .compactMap { $0 }
            .joined()
        case .parentUserId: return nil
        }
    }

    func sanitizedUuid(from value: String) throws -> UUIDv4 {
        let wrongType = Abort(.badRequest, reason: "Given value is not a valid UUID")
        switch self {
        case .emailAddress: throw wrongType
        case .parentUserId:
            guard let value = UUIDv4(value) else {
                throw wrongType
            }
            return value
        }
    }

    func sanitizedEmail(from value: String) throws -> NewEmail {
        let wrongType = Abort(.badRequest, reason: "Given value is not a valid UUID")
        switch self {
        case .emailAddress: return try NewEmail(sanitizing: value)
        case .parentUserId: throw wrongType
        }
    }

    func sanitize(_ value: String) throws -> String {
        switch self {
        case .emailAddress: return try NewEmail(sanitizing: value).value
        case .parentUserId: return try sanitizedUuid(from: value).value.uuidString.uppercased()
        }
    }

    var canBeUsedWithPassword: Bool {
        switch self {
        case .emailAddress: return true
        case .parentUserId: return false
        }
    }

    var stepsCapacity: StepsCapacity {
        switch self {
        case .emailAddress: return .value(1)
        case .parentUserId: return .bypass
        }
    }
}
