//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct UsersController: RouteCollection, ResourceController {
    typealias Resource = User

    func boot(routes: RoutesBuilder) throws {
        let me = routes.grouped("me")
        me.post(use: postMe)
        me.patch("validate-password", use: validatePassword)

        let passwordRecovery = me.grouped("password-recovery")
        passwordRecovery.post(use: createPasswordRecoveryCode)
        passwordRecovery.patch("validate-code", use: validatePasswordRecoveryCode)

        let auth = me.grouped(JWTUserBearerAuthenticator(), UserAuthResult.guardMiddleware())
        auth.get(use: getMe)
        auth.patch("mark-as-deleted", use: patchMeMarkAsDeleted)
        auth.patch("update-password", use: patchMeUpdatePassword)
        auth.group("auth-methods") { authMethods in
            authMethods.post(use: addAuthMethod)
            authMethods.patch("validate-verification-code", use: validateEmailCheckCode)
            let method = authMethods.grouped(":methodId")
            method.delete(use: removeAuthMethod)
            method.patch("create-verification-code", use: createEmailCheckCode)
        }
        auth.group("subaccounts") { others in
            others.post(use: postSomebodyElse)
            others.get(use: getSubaccounts)
            others.patch("new-session", use: patchSomebodyElseSession)
        }
    }

    func validatePassword(request: Request) throws -> EventLoopFuture<PasswordValidationReport> {
        let body = try request.content.decode(PasswordValidation.self)
        return request.eventLoop.future(PasswordValidationReport(with: body.password))
    }

    func validatePasswordRecoveryCode(request: Request) throws -> EventLoopFuture<Response> {
        let body = try request.content.decode(PasswordRecoveryCodeValidation.self)
        guard let code = request.application.passwordRecoveryCodes.findByCode(body.code) else {
            throw Abort(.badRequest, reason: "Code does not exist")
        }
        let repository = UsersRepository(database: request.db)
        return repository.find(code.userId)
            .unwrap(or: Abort(.badRequest, reason: "The user does not exist"))
            .flatMapThrowing {
                let userId = try $0.id.require()
                $0.passwordHash = try body.newPassword.hashed(using: request.password.hash)
                return repository.save($0).map {
                    request.application.passwordRecoveryCodes.clearForUserId(userId)
                }
            }
            .flatMap { $0 }
            .map { Response(status: .noContent) }
    }

    func createPasswordRecoveryCode(request: Request) throws -> EventLoopFuture<Response> {
        let body = try request.content.decode(PasswordRecoveryCodeNew.self)

        return try UsersRepository(database: request.db)
            .findByAuthMethodDescription(body.authMethodValue, body.authMethodType)
            .flatMapThrowing { (searchResult: (authMethod: AuthMethod, user: User)?) -> EventLoopFuture<Response> in
                let response = Response(status: .noContent)
                guard let (method, user) = searchResult else {
                    return request.eventLoop.future(response)
                }
                let methodId = try method.id.require()
                let userId = try user.id.require()
                let code = request.application.passwordRecoveryCodes.generateCode(for: methodId, and: userId)
                switch method.type {
                case .parentUserId:
                    throw Abort(.badRequest, reason: "This type of method does not support password recovery")
                case .emailAddress:
                    let email = Email<EmailPasswordRecoveryCode>(
                        body: .init(code: code.code),
                        subject: "Récupération de mot de passe",
                        recipient: method.value
                    )

                    if !request.application.environment.isRelease {
                        request.logger
                            .info("Generated code: \"\(code.code)\" for \"\(method.type)\": \"\(method.value)\"")
                    }
                    guard let emailClient = EmailApiClient.current else {
                        guard request.application.environment.name == "xcode" else {
                            throw Abort(.internalServerError, reason: "Failed to initiate the email client")
                        }

                        return request.eventLoop.future(response)
                    }
                    return emailClient.send(email, using: request.application).map { _ in response }
                }
            }
            .flatMap { $0 }
    }

    private static func could(_ user: User, stillAuthenticateConsidering methods: [AuthMethod]) -> Bool {
        let userHasBypassMethod = methods.first(where: { $0.type.stepsCapacity.isBypass }) != nil
        guard !userHasBypassMethod else { return true }

        let userHasPassword = user.passwordHash?.nilIfEmptyOrWhitespace() != nil
        let userHasMethodToUsePassword = methods.first(where: { $0.type.canBeUsedWithPassword }) != nil
        let canUserUsePassword = userHasPassword && userHasMethodToUsePassword
        let stepsCapacity = (canUserUsePassword ? 1 : 0) + methods
            .map { $0.type.stepsCapacity.value ?? 0 }
            .reduce(0, +)

        return stepsCapacity >= user.minimumAuthStepCount
    }

    func removeAuthMethod(request: Request) throws -> EventLoopFuture<Response> {
        let authResult = try request.auth.require(UserAuthResult.self)
        let methodId: UUIDv4 = try request.parameters.get("methodId").require()
        let methodsRepository = AuthMethodsRepository(database: request.db)

        return methodsRepository
            .methods(for: authResult.userId.value)
            .flatMapThrowing { (methods: [AuthMethod]) -> EventLoopFuture<Void> in
                guard let method = methods.first(where: { $0.id == methodId.value }) else { throw Abort(.notFound) }
                let otherMethods = methods.filter { $0.id != methodId.value }
                guard Self.could(authResult.user, stillAuthenticateConsidering: otherMethods) else {
                    throw Abort(
                        .badRequest,
                        reason: "Removing this method would prevent any further authentication on this account."
                    )
                }
                return methodsRepository.delete(method)
            }
            .flatMap { $0 }
            .map { Response(status: .noContent) }
    }

    func addAuthMethod(request: Request) throws -> EventLoopFuture<AuthMethodResponse> {
        let authResult = try request.auth.require(UserAuthResult.self)
        let body = try request.content.decode(UserAddAuthMethod.self)

        let repository = AuthMethodsRepository(database: request.db)
        let methods: EventLoopFuture<[AuthMethod]>
        let methodId = body.id?.value ?? .init()

        let sanitizedValue: String = try body.type.sanitize(body.value)
        switch body.type {
        case .emailAddress:
            let existingMethodWithEmail = UsersRepository(database: request.db).findByEmail(sanitizedValue)

            methods = existingMethodWithEmail
                .guard({ $0 == nil }, else: SpecificError.emailAddressAlreadyAssociated)
                .flatMap { _ in repository.methods(for: authResult.userId.value) }
        case .parentUserId:
            let parentId = try body.type.sanitizedUuid(from: body.value)
            guard parentId != authResult.userId else {
                throw Abort(.badRequest, reason: "The parent user cannot be this user")
            }
            let parent = UsersRepository(database: request.db).find(parentId.value)

            methods = parent.unwrap(or: Abort(.notFound, reason: "Could not find parent with id: \(parentId.value)"))
                .flatMap { _ in repository.methods(for: authResult.userId.value) }
        }
        return methods
            .flatMapThrowing { methods -> AuthMethod in
                guard methods.allSatisfy({ !($0.type == body.type && $0.value == sanitizedValue) }) else {
                    throw Abort(.badRequest, reason: "Such a method already exists")
                }
                return AuthMethod(id: methodId, userId: authResult.userId.value, value: sanitizedValue, type: body.type)
            }
            .flatMap { repository.saving($0) }
            .flatMapThrowing { try AuthMethodResponse.make(from: $0, and: request) }
            .flatMap { $0 }
    }

    func getSubaccounts(request: Request) throws -> EventLoopFuture<[UserResponse]> {
        try defaultReadList(resourcesProvider: {
            let authResult = try $0.auth.require(UserAuthResult.self)
            return UsersRepository(database: request.db).subaccounts(ofUser: authResult.userId.value).map { $0 }
        })(request)
    }

    func getMe(request: Request) throws -> EventLoopFuture<UserResponse> {
        try defaultReadOne(resourceProvider: {
            let user: User = try $0.auth.require(UserAuthResult.self).user
            return $0.eventLoop.makeSucceededFuture(user)
        })(request)
    }

    func patchMeUpdatePassword(request: Request) throws -> EventLoopFuture<UserResponse> {
        let user: User = try request.auth.require(UserAuthResult.self).user
        let passwordUpdate = try request.content.decode(UserPasswordUpdate.self)
        return UsersRepository(database: request.db)
            .updatingPassword(user, with: passwordUpdate, request.password.hash)
            .flatMapThrowing { try UserResponse.make(from: $0, and: request) }
            .flatMap { $0 }
    }

    func patchMeMarkAsDeleted(request: Request) throws -> EventLoopFuture<UserResponse> {
        let user: User = try request.auth.require(UserAuthResult.self).user
        return UsersRepository(database: request.db)
            .markingAsDeleted(user)
            .flatMapThrowing { try UserResponse.make(from: $0, and: request) }
            .flatMap { $0 }
    }

    func postMe(request: Request) throws -> EventLoopFuture<UserResponse> {
        let newMe = try request.content.decode(UserNew.self)
        return UsersRepository(database: request.db)
            .creating(newMe, request.password.hash)
            .flatMapThrowing { try UserResponse.make(from: $0, and: request) }
            .flatMap { $0 }
    }

    func postSomebodyElse(request: Request) throws -> EventLoopFuture<UserResponse> {
        let user: User = try request.auth.require(UserAuthResult.self).user
        let newSomebodyElse = try request.content.decode(SomebodyElseNew.self)
        return UsersRepository(database: request.db)
            .creating(user, newSomebodyElse)
            .flatMapThrowing { try UserResponse.make(from: $0, and: request) }
            .flatMap { $0 }
    }

    func patchSomebodyElseSession(request: Request) throws -> EventLoopFuture<SessionResponse> {
        let body = try request.content.decode(SomebodyElseNewSession.self)
        let authResult = try request.auth.require(UserAuthResult.self)
        return SessionsRepository(database: request.db).creatingSession(from: body, for: authResult.userId.value)
            .flatMapThrowing { try SessionResponse.make(from: $0, and: request) }
            .flatMap { $0 }
    }

    func validateEmailCheckCode(request: Request) throws -> EventLoopFuture<UserResponse> {
        let authResult = try request.auth.require(UserAuthResult.self)
        let body = try request.content.decode(EmailCheckCodeValidation.self)
        let database = request.db
        guard let code = request.application.emailCheckCodes.findByCode(body.code) else {
            throw Abort(.badRequest, reason: "Code does not exist")
        }
        return database.transaction { database -> EventLoopFuture<Void> in
            let methodsRepository = AuthMethodsRepository(database: database)
            let methods = methodsRepository.methods(for: authResult.userId.value)
            let authMethodId = code.authMethodId

            return methods
                .flatMap { (methods: [AuthMethod]) -> EventLoopFuture<Void> in
                    guard let method = methods.first(where: { $0.id == authMethodId }) else {
                        return request.eventLoop.makeFailedFuture(
                            Abort(.badRequest, reason: "Could not find method in associated methods")
                        )
                    }

                    method.verificationDate = .init()

                    return methodsRepository.save(method)
                        .map { _ in request.application.emailCheckCodes.clearForAuthMethodId(authMethodId) }
                }
        }
        .flatMapThrowing { _ in
            try UserResponse.make(from: authResult.user, and: request)
        }
        .flatMap { $0 }
    }

    func createEmailCheckCode(request: Request) throws -> EventLoopFuture<Response> {
        let authResult = try request.auth.require(UserAuthResult.self)
        let authMethodId: UUIDv4 = try request.parameters.get("methodId").require()
        let userId = authResult.userId.value
        let methods = AuthMethodsRepository(database: request.db).methods(for: userId)
        return methods
            .flatMapThrowing { methods -> EventLoopFuture<EmailCheckCode?> in
                guard let method = methods.first(where: { $0.id == authMethodId.value }) else {
                    throw Abort(.badRequest, reason: "Could not find method in associated methods")
                }
                guard method.type == .emailAddress else {
                    throw Abort(.badRequest, reason: "Method is not an email address")
                }
                guard method.verificationDate == nil else {
                    throw SpecificError.emailAddressAlreadyVerified
                }
                let code = request.application.emailCheckCodes.generateCode(for: authMethodId.value, and: userId)
                let email = Email<EmailEmailCheckCode>(
                    body: .init(code: code.code),
                    subject: "Ajout d'adresse: code de vérification",
                    recipient: method.value
                )

                if !request.application.environment.isRelease {
                    request.logger.info("Generated code: \"\(code.code)\" for \"\(method.type)\": \"\(method.value)\"")
                }
                guard let emailClient = EmailApiClient.current else {
                    guard request.application.environment.name == "xcode" else {
                        throw Abort(.internalServerError, reason: "Failed to initiate the email client")
                    }
                    return request.eventLoop.future()
                        .map { code }
                }
                return emailClient.send(email, using: request.application)
                    .map { code }
            }
            .flatMap { $0 }
            .map { code in
                var headers = HTTPHeaders()
                if [.testing, .development].contains(request.application.environment), let code = code?.code {
                    headers.add(name: "Code", value: code)
                }
                return Response(status: .noContent, headers: headers)
            }
    }
}
