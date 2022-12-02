//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct SessionsController: RouteCollection, ResourceController {
    typealias Resource = Session

    func boot(routes: RoutesBuilder) throws {
        routes
            .grouped(ForwardAuthenticator(), ServerAuthResult.guardMiddleware())
            .get("forward-auth", use: forward)

        let sessions = routes.grouped("sessions")
        sessions.post(use: defaultCreateOne(saveInsteadOfCreate: true))

        let userAuthenticated = sessions.grouped(JWTUserBearerAuthenticator(), UserAuthResult.guardMiddleware())
        userAuthenticated.get(use: defaultReadList(resourcesProvider: listAll))
        userAuthenticated.delete(":sessionId", use: defaultDeleteOne(
            idPathComponentName: "sessionId",
            resourceValidator: .init(checkDeletePermission(forSpecific:considering:))
        ))

        let sessionAuthenticated = sessions.grouped(SessionAuthenticator(), SessionAuthResult.guardMiddleware())
        sessionAuthenticated.group("current") { current in
            current.get(use: currentSession)
            current.delete(use: defaultDeleteOne(resourceProvider: currentSession))
            current.get("next-steps", use: listAvailableMethods)
            current.patch("new-access-token", use: accessToken)
            current.patch("run-extra-auth", use: runExtraAuth)
            current.patch("create-auth-code", use: createAuthCode)
            current.patch("validate-auth-code", use: validateAuthCode)
        }
    }

    private func getAvailableMethods(
        user: User,
        steps: [AuthStep],
        methods: [AuthMethod]
    ) -> [AuthMethodShortResponse] {
        let userHasPassword = user.passwordHash?.nilIfEmptyOrWhitespace() != nil
        let userAlreadyUsedPassword = steps.first(where: { $0.type == .password }) != nil
        let userCanUsePassword = userHasPassword && !userAlreadyUsedPassword
        let availableMethods: [AuthMethodShortResponse] = methods
            .reduce(into: []) { (availableMethods: inout [AuthMethodShortResponse], method: AuthMethod) in
                guard let methodId = try? method.id.flatMap(UUIDv4.init) else { return }
                var allTypes: Set<AuthStepType>
                switch method.type {
                case .emailAddress:
                    allTypes = [.ephemeralCode]
                case .parentUserId: return
                }
                let usedTypes = Set(steps.filter { $0.authMethodId == method.id }.map(\.type))
                if method.type.canBeUsedWithPassword, userCanUsePassword {
                    allTypes.insert(.password)
                }
                let availableTypes = allTypes.subtracting(usedTypes)
                let authMethodShortMethod = AuthMethodShortResponse(
                    methodId: methodId,
                    methodValuePreview: method.type.preview(from: method.value),
                    methodType: method.type,
                    stepTypes: availableTypes
                )
                availableMethods.append(authMethodShortMethod)
            }
        return availableMethods
    }

    func listAvailableMethods(request: Request) throws -> EventLoopFuture<[AuthMethodShortResponse]> {
        let authResult: SessionAuthResult = try request.auth.require()

        let user = UsersRepository(database: request.db).find(authResult.session.userId)
            .unwrap(or: Abort(.internalServerError, reason: "Could not find the user for the current session"))
        let steps = AuthStepsRepository(database: request.db).steps(for: authResult.sessionId.value)
        let methods = AuthMethodsRepository(database: request.db).methods(for: authResult.session.userId)

        return user.and(steps.and(methods))
            .map { user, values -> [AuthMethodShortResponse] in
                self.getAvailableMethods(user: user, steps: values.0, methods: values.1)
            }
    }

    func validateAuthCode(request: Request) throws -> EventLoopFuture<SessionResponse> {
        let authResult: SessionAuthResult = try request.auth.require()
        let body = try request.content.decode(AuthCodeValidation.self)
        let userId = authResult.session.userId
        let database = request.db
        guard let code = request.application.authCodes.findByCode(body.code) else {
            throw Abort(.badRequest, reason: "Code does not exist")
        }
        return database.transaction { database -> EventLoopFuture<SessionResponse> in
            let methodsRepository = AuthMethodsRepository(database: database)
            let methods = methodsRepository.methods(for: userId)
            let stepsRepository = AuthStepsRepository(database: database)
            let steps = stepsRepository.steps(for: authResult.sessionId.value)
            let authMethodId = code.authMethodId
            return methods.and(steps)
                .flatMapThrowing { methods, steps -> EventLoopFuture<Void> in
                    guard let method = methods.first(where: { $0.id == authMethodId }) else {
                        throw Abort(.badRequest, reason: "Could not find method in associated methods")
                    }
                    guard steps.first(where: { $0.authMethodId == authMethodId && $0.type == .ephemeralCode }) == nil
                    else {
                        throw Abort(.badRequest, reason: "Method already used for this session")
                    }
                    let step = AuthStep(
                        sessionId: authResult.sessionId.value,
                        type: .ephemeralCode,
                        authMethodId: authMethodId
                    )
                    var updates: [EventLoopFuture<Void>] = [stepsRepository.save(step)]
                    if method.verificationDate == nil {
                        method.verificationDate = .init()
                        updates.append(methodsRepository.save(method))
                    }

                    return EventLoopFuture<Void>.andAllSucceed(updates, on: request.eventLoop)
                        .map { _ in request.application.authCodes.clearForAuthMethodId(authMethodId) }
                }
                .flatMap { $0 }
                .flatMapThrowing { _ in
                    try SessionResponse.make(from: authResult.session, and: request, on: database)
                }
                .flatMap { $0 }
        }
    }

    func createAuthCode(request: Request) throws -> EventLoopFuture<Response> {
        let authResult: SessionAuthResult = try request.auth.require()
        let body = try request.content.decode(AuthCodeNew.self)
        let userId = authResult.session.userId
        let authMethodId = body.authMethodId.value
        let methods = AuthMethodsRepository(database: request.db).methods(for: userId)
        let steps = AuthStepsRepository(database: request.db).steps(for: authResult.sessionId.value)
        return methods.and(steps)
            .flatMapThrowing { methods, steps -> EventLoopFuture<AuthCode?> in
                guard let method = methods.first(where: { $0.id == authMethodId }) else {
                    throw Abort(.badRequest, reason: "Could not find method in associated methods")
                }
                guard steps.first(where: { $0.authMethodId == authMethodId && $0.type == .ephemeralCode }) == nil else {
                    throw Abort(.badRequest, reason: "Method already used for this session")
                }
                let code = request.application.authCodes.generateCode(for: authMethodId, and: userId)
                let email = Email<EmailAuthCode>(
                    body: .init(code: code.code),
                    subject: "Authentification: code de vérification",
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
                        .map { nil }
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

    func checkDeletePermission(forSpecific session: Session, considering request: Request) throws {
        let authResult: UserAuthResult = try request.auth.require()
        guard session.userId == authResult.userId.value else { throw Abort(.forbidden) }
    }

    func listAll(request: Request) throws -> EventLoopFuture<[Session]?> {
        let authResult: UserAuthResult = try request.auth.require()
        return SessionsRepository(database: request.db).sessions(for: authResult.userId.value).map { $0 }
    }

    func currentSession(request: Request) throws -> EventLoopFuture<SessionResponse> {
        let authResult: SessionAuthResult = try request.auth.require()
        return try SessionResponse.make(from: authResult.session, and: request)
    }

    func currentSession(request: Request) throws -> EventLoopFuture<Session?> {
        let authResult: SessionAuthResult = try request.auth.require()
        return request.eventLoop.future(authResult.session)
    }

    func forward(request: Request) throws -> EventLoopFuture<Response> {
        let authResult: ServerAuthResult = try request.auth.require()

        var headers: HTTPHeaders = .init()
        headers.nxServerAuthResult = authResult

        let response: Response = .init(status: .ok, headers: headers, body: .empty)
        return request.eventLoop.makeSucceededFuture(response)
    }

    func accessToken(request: Request) throws -> EventLoopFuture<AccessTokenResponse> {
        let authResult: SessionAuthResult = try request.auth.require()
        let extraSteps = ExtraAuthStepsRepository(database: request.db).steps(for: authResult.sessionId.value)
        let steps = AuthStepsRepository(database: request.db).steps(for: authResult.sessionId.value)
        let usersRepository = UsersRepository(database: request.db)
        let user = usersRepository.findBySessionToken(token: authResult.session.token)
        let subaccounts = usersRepository.subaccounts(ofUser: authResult.session.userId)

        return user.and(subaccounts).and(steps.and(extraSteps))
            .flatMapThrowing { (values: (user: User?, subaccounts: [User]), steps: ([AuthStep], [ExtraAuthStep])) in
                guard let user = values.user else {
                    throw Abort(.internalServerError, reason: "Failed to locate user for session")
                }
                let wasCreatedByParent = steps.0.first(where: { $0.type == .parentUser }) != nil
                let isDev = request.application.environment.name == "xcode"
                guard steps.0.count >= user.minimumAuthStepCount || wasCreatedByParent || isDev else {
                    throw Abort(
                        .forbidden,
                        reason: "This user requires a minimum of \(user.minimumAuthStepCount) auth steps"
                    )
                }

                let extraAuthKeys = Set(steps.1.map(\.key))
                let missingExtraAuthKeys = PublicConfiguration.current.requiredExtraAuthSteps.subtracting(extraAuthKeys)
                guard missingExtraAuthKeys.isEmpty else {
                    throw Abort(
                        .forbidden,
                        reason: "Missing extra auth steps: \(missingExtraAuthKeys.joined(separator: ", "))"
                    )
                }

                let content = try JWTUser(
                    authResult: authResult,
                    userId: try .init(value: user.id.require()),
                    sessionId: authResult.sessionId,
                    subaccounts: try values.subaccounts.map { try UUIDv4(value: $0.id.require()) },
                    extraAuthSteps: steps.1
                )
                let token = try request.jwt.sign(content, kid: .private)
                return AccessTokenResponse(accessToken: token)
            }
    }

    private func runExtraAuth(request: Request) throws -> EventLoopFuture<Response> {
        let body = try request.content.decode(ExtraAuthStepRun.self)

        let authResult: SessionAuthResult = try request.auth.require()
        let user = UsersRepository(database: request.db).findBySessionToken(token: authResult.session.token)

        return user
            .optionalMap { $0.id }
            .unwrap(or: Abort(.internalServerError, reason: "Failed to locate the user for this session"))
            .flatMapThrowing { userId in
                try ExtraAuth(key: body.key, content: body.content, userId: try .init(value: userId)).run(for: request)
            }
            .flatMap { $0 }
            .flatMapThrowing(
                { (response: ExtraAuthResponse<JsonValue>) -> EventLoopFuture<ExtraAuthResponse<JsonValue>> in
                    let step = try ExtraAuthStep(
                        id: response.id.value,
                        sessionId: authResult.sessionId.value,
                        key: body.key,
                        payload: response.content
                    )
                    return ExtraAuthStepsRepository(database: request.db).save(step).map { response }
                }
            )
            .flatMap { $0.encodeResponse(status: .ok, for: request) }
            .flatMapErrorThrowing {
                if let error = $0 as? ExtraAuthError, case .extraAuthFailed(let response) = error {
                    return response
                } else {
                    throw $0
                }
            }
    }
}
