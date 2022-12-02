//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Foundation
import Vapor

internal typealias UsersRepository = DefaultRepository<User>

extension UsersRepository {
    func findBySessionToken(token: Data) -> EventLoopFuture<User?> {
        Session.query(on: database)
            .filter(\.$token == token)
            .field(\.$userId)
            .first()
            .optionalFlatMap {
                User.query(on: self.database)
                    .filter(\.$id == $0.userId)
                    .first()
            }
    }

    func findByEmail(_ email: String) -> EventLoopFuture<(authMethod: AuthMethod, user: User)?> {
        AuthMethod.query(on: database)
            .filter(\.$value == email)
            .filter(\.$type == AuthMethodType.emailAddress)
            .first()
            .optionalFlatMap { method in
                User.find(method.userId, on: self.database).map { $0.flatMap { (method, $0) } }
            }
    }

    func findByAuthMethodDescription(
        _ value: String,
        _ type: AuthMethodType
    ) throws -> EventLoopFuture<(authMethod: AuthMethod, user: User)?> {
        let sanitizedValue: String
        switch type {
        case .emailAddress:
            sanitizedValue = value
        case .parentUserId:
            guard let parentId = UUIDv4(value) else {
                throw Abort(.badRequest, reason: "Parent user ID is not a valid v4 UUID")
            }
            sanitizedValue = parentId.value.uuidString.uppercased()
        }

        return AuthMethod.query(on: database)
            .filter(\.$value == sanitizedValue)
            .filter(\.$type == type)
            .first()
            .optionalFlatMap { method in
                User.find(method.userId, on: self.database).map { $0.flatMap { (method, $0) } }
            }
    }

    func find(
        _ userId: User.IDValue,
        forParent parentId: User.IDValue
    ) -> EventLoopFuture<(authMethod: AuthMethod, user: User, parent: User)?> {
        AuthMethod.query(on: database)
            .filter(\.$userId == userId)
            .filter(\.$value == parentId.uuidString.uppercased())
            .filter(\.$type == AuthMethodType.parentUserId)
            .first()
            .optionalFlatMap { method in
                let user = User.find(userId, on: self.database)
                let parent = User.find(parentId, on: self.database)
                return user.and(parent).map {
                    guard let user = $0 else { return nil }
                    guard let parent = $1 else { return nil }
                    return (method, user, parent)
                }
            }
    }

    func subaccounts(ofUser userId: User.IDValue) -> EventLoopFuture<[User]> {
        AuthMethod.query(on: database)
            .filter(\.$type == .parentUserId)
            .filter(\.$value == userId.uuidString.uppercased())
            .all(\.$userId)
            .map(Set.init)
            .flatMap { User.query(on: self.database).filter(\.$id ~~ $0).all() }
    }

    func updatingPassword(
        _ user: User,
        with passwordUpdate: UserPasswordUpdate,
        _ hasher: (_ password: String) throws -> String
    ) -> EventLoopFuture<User> {
        do {
            try user.passwordHash = passwordUpdate.newPassword.hashed(using: hasher)
            return updating(user)
        } catch {
            return database.eventLoop.makeFailedFuture(error)
        }
    }

    func creating(
        _ currentUser: User,
        _ newUser: SomebodyElseNew
    ) -> EventLoopFuture<User> {
        do {
            let currentUserId = try currentUser.id.require()
            let newUserId = newUser.id?.value ?? .init()
            let newUser = User(id: newUserId, passwordHash: nil)
            let authMethod = AuthMethod(
                id: .init(),
                userId: newUserId,
                value: currentUserId.uuidString.uppercased(),
                type: .parentUserId
            )
            let methodsRepository = AuthMethodsRepository(database: database)
            return methodsRepository.create(authMethod)
                .flatMap { self.creating(newUser, on: self.database) }
        } catch {
            return database.eventLoop.makeFailedFuture(error)
        }
    }

    func creating(_ newUser: UserNew, _ hasher: (_ password: String) throws -> String) -> EventLoopFuture<User> {
        do {
            let userId = newUser.id?.value ?? .init()
            let user = User(id: userId, passwordHash: try newUser.password.hashed(using: hasher))
            let authMethod = AuthMethod(
                id: .init(),
                userId: userId,
                value: newUser.email.value,
                type: .emailAddress
            )
            let methodsRepository = AuthMethodsRepository(database: database)
            return methodsRepository.methods(for: newUser.email.value, from: database)
                .flatMapThrowing { guard $0.isEmpty else { throw SpecificError.emailAddressAlreadyAssociated } }
                .flatMap { methodsRepository.create(authMethod) }
                .flatMap { self.creating(user, on: self.database) }
        } catch {
            return database.eventLoop.makeFailedFuture(error)
        }
    }
}
