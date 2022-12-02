//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import JWT
import Vapor

internal struct JwtConfiguration: AppConfiguration {
    func configure(_ application: Application) throws {
        let privateSigner: JWTSigner = try Environment.require(
            key: "AUTH_JWT_PRIVATE_KEY",
            using: { try .rs256(key: .private(pem: $0.splittingEnvironmentInlineBase64())) }
        )
        let publicSigner: JWTSigner = try Environment.require(
            key: "AUTH_JWT_PUBLIC_KEY",
            using: { try .rs256(key: .public(pem: $0.splittingEnvironmentInlineBase64())) }
        )

        application.jwt.signers.use(privateSigner, kid: .private)
        application.jwt.signers.use(publicSigner, kid: .public, isDefault: true)
    }
}
