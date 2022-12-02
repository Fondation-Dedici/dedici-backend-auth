//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import Fluent
import Foundation
import Vapor

internal typealias SessionsRepository = DefaultRepository<Session>

extension SessionsRepository {
    func findByToken(token: Data) -> EventLoopFuture<Session?> {
        Session.query(on: database)
            .filter(\.$token == token)
            .first()
    }

    func sessions(for userId: User.IDValue) -> EventLoopFuture<[Session]> {
        Session.query(on: database)
            .filter(\.$userId == userId)
            .all()
    }

    func creatingSession(
        from newSession: SomebodyElseNewSession,
        for parentId: User.IDValue
    ) -> EventLoopFuture<Session> {
        UsersRepository(database: database).find(newSession.userId.value, forParent: parentId)
            .unwrap(or: Abort(.unauthorized))
            .flatMapThrowing { (authMethod: AuthMethod, user: User, parent: User) throws -> (AuthMethod, User, User) in

                guard !user.hasBeenDeleted else { throw Abort(.unauthorized) }
                guard !user.hasBeenDisabled else { throw Abort(.unauthorized) }

                return (authMethod, user, parent)
            }
            .flatMapThrowing { (authMethod: AuthMethod, user: User, _: User) -> EventLoopFuture<Session> in
                let sessionId = UUID()
                let session = Session(
                    id: sessionId,
                    userId: try user.id.require(),
                    maxAge: newSession.maxAge?.value,
                    minimumAuthStepCount: 1
                )
                let step = AuthStep(sessionId: sessionId, type: .parentUser, authMethodId: try authMethod.id.require())
                var updates: [EventLoopFuture<Void>] = [step.save(on: self.database)]
                if authMethod.verificationDate == nil {
                    authMethod.verificationDate = .init()
                    updates.append(authMethod.save(on: self.database))
                }

                return EventLoopFuture<Void>
                    .andAllSucceed(updates, on: self.database.eventLoop)
                    .flatMap {
                        self.creating(session)
                    }
            }
            .flatMap { $0 }
    }

    func creatingSession(
        from newSession: SessionNew,
        using passwordChecker: @escaping (_ password: String, _ hash: String) throws -> Bool
    ) -> EventLoopFuture<Session> {
        UsersRepository(database: database)
            .findByEmail(newSession.email)
            .unwrap(or: Abort(.unauthorized))
            .flatMapThrowing { (authMethod: AuthMethod, user: User) throws -> (authMethod: AuthMethod, user: User) in
                guard let passwordHash = user.passwordHash else { throw Abort(.unauthorized) }
                guard try passwordChecker(newSession.password, passwordHash) else { throw Abort(.unauthorized) }
                guard !user.hasBeenDeleted else { throw Abort(.unauthorized) }
                guard !user.hasBeenDisabled else { throw Abort(.unauthorized) }

                return (authMethod, user)
            }
            .flatMapThrowing { (authMethod: AuthMethod, user: User) -> EventLoopFuture<Session> in
                let sessionId = UUID()
                let session = Session(
                    id: sessionId,
                    userId: try user.id.require(),
                    maxAge: newSession.maxAge?.value,
                    minimumAuthStepCount: user.minimumAuthStepCount
                )
                let step = AuthStep(sessionId: sessionId, type: .password, authMethodId: try authMethod.id.require())

                return step.create(on: self.database).flatMap {
                    self.creating(session)
                }
            }
            .flatMap { $0 }
    }
}
