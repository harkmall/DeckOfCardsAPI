//
//  User.swift
//  App
//
//  Created by Mark Hall on 2017-12-05.
//

import Vapor
import FluentProvider
import HTTP
import AuthProvider

final class User: Model {
    let storage = Storage()
    
    var email: String
    var password: String?
    
    struct Keys {
        static let id = "id"
        static let email = "email"
        static let password = "password"
    }
    
    init(email: String, password: String? = nil) {
        self.email = email
        self.password = password
    }
    
    init(row: Row) throws {
        email = try row.get(User.Keys.email)
        password = try row.get(User.Keys.password)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(User.Keys.email, email)
        try row.set(User.Keys.password, password)
        return row
    }
}

extension User: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(User.Keys.email)
            builder.string(User.Keys.password)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension User: JSONConvertible {
    convenience init(json: JSON) throws {
        self.init(
            email: try json.get(User.Keys.email)
        )
        id = try json.get(User.Keys.id)
    }

    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(User.Keys.id, id)
        try json.set(User.Keys.email, email)
        return json
    }
}

extension User: ResponseRepresentable { }

// MARK: Password
extension User: PasswordAuthenticatable {
    var hashedPassword: String? {
        return password
    }

    public static var passwordVerifier: PasswordVerifier? {
        get { return _userPasswordVerifier }
        set { _userPasswordVerifier = newValue }
    }
}

// store private variable since storage in extensions
// is not yet allowed in Swift
private var _userPasswordVerifier: PasswordVerifier? = nil


