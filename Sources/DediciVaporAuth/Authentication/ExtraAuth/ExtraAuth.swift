//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import NIO
import Vapor

internal struct ExtraAuth {
    let key: String
    let content: JsonValue
    let userId: UUIDv4
    let url: URL
    let timeout: Int

    init(key: String, content: JsonValue, userId: UUIDv4, timeout: Int? = nil) throws {
        let key = try Self.sanitizedKey(from: key)
        let url = try Self.extraAuthUrl(for: key)
        let timeout = try Self.extraAuthTimeout(for: key, timeout: timeout)

        self.key = key
        self.content = content
        self.userId = userId
        self.url = url
        self.timeout = timeout
    }

    func run(for request: Request) -> EventLoopFuture<ExtraAuthResponse<JsonValue>> {
        var headers: HTTPHeaders = .init()
        headers.contentType = .json
        let extraRequest: HTTPClient.Request
        do {
            let encoder: JSONEncoder = ContentConfiguration.jsonEncoder
            let reqContent = ExtraAuthRequest(userId: userId, content: content)
            let data = try encoder.encode(reqContent)
            extraRequest = try HTTPClient.Request(
                url: url,
                method: .POST,
                headers: headers,
                body: .data(data)
            )
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
        return request.application.http.client.shared
            .execute(
                request: extraRequest,
                eventLoop: .delegateAndChannel(on: request.eventLoop),
                deadline: .now() + .seconds(.init(timeout))
            )
            .flatMapThrowing { (response: HTTPClient.Response) -> ExtraAuthResponse<JsonValue> in

                guard
                    response.status == .ok,
                    var body = response.body,
                    let data = body.readData(length: body.readableBytes),
                    let jsonValue = try? ContentConfiguration.jsonDecoder
                        .decode(ExtraAuthResponse<JsonValue>.self, from: data)
                else {
                    let buffer = response.body
                    let nxErrorCode = response.headers.nxErrorCode?.nilIfEmptyOrWhitespace()
                    guard buffer != nil || nxErrorCode != nil else {
                        throw Abort(.internalServerError, reason: "Failed to read body")
                    }
                    let forwardedResponse = Response(
                        status: response.status,
                        version: response.version,
                        headers: response.headers,
                        body: buffer.flatMap { .init(buffer: $0) } ?? .empty
                    )
                    throw ExtraAuthError.extraAuthFailed(response: forwardedResponse)
                }

                return jsonValue
            }
    }

    private static func extraAuthTimeout(for key: String, timeout: Int?) throws -> Int {
        let envKey = try Self.environmentKeyPart(from: key)
        let envTimeout = try? Environment.require(
            key: "AUTH_EXTRA_\(envKey)_TIMEOUT",
            using: { Int($0) }
        )
        return timeout ?? envTimeout ?? 5
    }

    private static func extraAuthUrl(for key: String) throws -> URL {
        let envKey = try Self.environmentKeyPart(from: key)
        do {
            return try Environment.require(key: "AUTH_EXTRA_\(envKey)_URL", using: URL.init(string:))
        } catch {
            throw ExtraAuthError.failedToIdentify(key: key)
        }
    }

    public static func requiredExtraAuthKeys() throws -> Set<String> {
        let rawString = (try? Environment.require(key: "AUTH_REQUIRED_EXTRA")) ?? ""
        return Set(try rawString.components(separatedBy: ",").map(sanitizedKey))
    }

    private static func sanitizedKey(from key: String) throws -> String {
        let key = key.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !key.hasPrefix("_"), !key.hasSuffix("_")
        else {
            throw ExtraAuthError.keyCannotBeginNorEndWithUnderscores(key: key)
        }

        let illegalChars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz_").inverted
        let illegalCharsInKey = Set(key.unicodeScalars.filter(illegalChars.contains))
        guard illegalCharsInKey.isEmpty
        else {
            throw ExtraAuthError.illegalCharactersInKey(key: key, characters: illegalCharsInKey.sorted())
        }

        return key
    }

    private static func environmentKeyPart(from key: String) throws -> String {
        key.uppercased()
    }
}
