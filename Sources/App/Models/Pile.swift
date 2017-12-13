//
//  Pile.swift
//  App
//
//  Created by Mark Hall on 2017-12-13.
//

import Vapor
import FluentProvider

final class Pile: Model {
    let storage = Storage()
    
    var name: String
    var deckId: Identifier?
    var cards: Children<Pile, Card> {
        return children()
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("name", name)
        try row.set(Deck.foreignIdKey, deckId)
        return row
    }
    
    init(row: Row) throws {
        name = try row.get("name")
        deckId = try row.get(Deck.foreignIdKey)
    }
    
    init(name: String, deck: Deck) {
        self.name = name
        self.deckId = deck.id
    }
    
    init(fromAPIJSON: JSON) {
        self.name = ""
    }
}

extension Pile: ResponseRepresentable {}

extension Pile: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string("name")
            builder.parent(Deck.self)
        }
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Pile: JSONConvertible {
    convenience init(json: JSON) throws {
        self.init(fromAPIJSON: json)
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(name, try cards.all().makeJSON())
        try json.set("remaining", try cards.all().count)
        return json
    }
}


