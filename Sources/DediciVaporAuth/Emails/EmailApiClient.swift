//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import NIO
import Vapor

internal struct EmailApiClient {
    static let current: EmailApiClient? = {
        guard let url = try? Environment.require(key: "NX_EMAIL_SERVICE_URL", using: URL.init(string:)) else {
            return nil
        }
        guard let timeout = try? Environment.require(key: "NX_EMAIL_SERVICE_TIMEOUT", using: Int64.init(_:)) else {
            return nil
        }

        return .init(url: url, timeout: timeout)
    }()

    let url: URL
    let timeout: Int64

    func send<Body: EmailBody>(_ email: Email<Body>, using application: Application) -> EventLoopFuture<Void> {
        var headers: HTTPHeaders = .init()
        headers.contentType = .json
        let extraRequest: HTTPClient.Request
        do {
            let encoder: JSONEncoder = ContentConfiguration.jsonEncoder
            let data = try encoder.encode(email)
            extraRequest = try HTTPClient.Request(
                url: url,
                method: .POST,
                headers: headers,
                body: .data(data)
            )
        } catch {
            return application.eventLoopGroup.future(error: error)
        }

        return application.http.client.shared
            .execute(
                request: extraRequest,
                eventLoop: .delegateAndChannel(on: application.eventLoopGroup.next()),
                deadline: .now() + .seconds(timeout)
            )
            .flatMapThrowing {
                guard (200 ..< 300).contains($0.status.code) else {
                    throw Abort(.internalServerError)
                }
            }
    }
}
