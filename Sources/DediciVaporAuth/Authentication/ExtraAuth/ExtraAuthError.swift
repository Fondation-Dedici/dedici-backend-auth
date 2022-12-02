//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

internal enum ExtraAuthError: Error {
    case failedToIdentify(key: String)
    case contentWasNotValidUtf8(key: String)
    case contentWasEmpty(key: String)
    case contentWasNotValidJson(key: String)
    case extraAuthFailed(response: Response)
    case illegalCharactersInKey(key: String, characters: [String.UnicodeScalarView.Element])
    case keyCannotBeginNorEndWithUnderscores(key: String)
}
