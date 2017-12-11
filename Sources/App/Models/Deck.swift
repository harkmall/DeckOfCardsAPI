//
//  Deck.swift
//  DeckOfCardsAPIPackageDescription
//
//  Created by Mark Hall on 2017-12-11.
//

import Vapor
import FluentProvider

final class Deck: Model {
    let storage = Storage()
    
    var shuffled: Bool
    var cards: Children<Deck, Card> {
        return children()
    }
    
    func makeRow() throws -> Row {
        return Row()
    }
    
    init(row: Row) throws {
        shuffled = try row.get("shuffled")
    }
    
    init(shuffle: Bool) {
        self.shuffled = shuffle
    }
}

extension Deck: ResponseRepresentable {}

// MARK: Fluent Preparation

extension Deck: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.bool("shuffled")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Deck: JSONConvertible {
    convenience init(json: JSON) throws {
        self.init(
            shuffle: try json.get("shuffled")
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("deckId", id)
        try json.set("shuffled", shuffled)
        try json.set("cards", cards.all().makeJSON())
        return json
    }
}
