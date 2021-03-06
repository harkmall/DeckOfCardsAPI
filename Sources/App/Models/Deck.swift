//
//  Deck.swift
//  DeckOfCardsAPIPackageDescription
//
//  Created by Mark Hall on 2017-12-11.
//

import Vapor
import FluentProvider
import Foundation
import Random

final class Deck: Model {
    let storage = Storage()
    
    var shuffled: Bool
    var lastUpdated: Date
    var cards: Children<Deck, Card> {
        return children()
    }
    var piles: Children<Deck, Pile> {
        return children()
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("shuffled", shuffled)
        try row.set("lastUpdated", lastUpdated)
        return row
    }
    
    init(row: Row) throws {
        shuffled = try row.get("shuffled")
        lastUpdated = try row.get("lastUpdated")
    }
    
    init(shuffle: Bool) {
        self.shuffled = shuffle
        self.lastUpdated = Date()
    }
}

extension Deck: ResponseRepresentable {}

// MARK: Fluent Preparation

extension Deck: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.bool("shuffled")
            builder.date("lastUpdated")
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
        try json.set("remaining", try cards.all().count)
        try json.set("cards", try cards.all().makeJSON())
        
        var pileJSON = JSON()
        for pile in try piles.all() {
            var innerJSON = JSON()
            try innerJSON.set("remaining", pile.cards.all().count)
            try innerJSON.set("cards", pile.cards.all().makeJSON())
            try pileJSON.set(pile.name, innerJSON)
        }
        try json.set("piles", pileJSON)
        
        return json
    }
}

extension Array {
    mutating func shuffle() {
        for i in 0 ..< (count - 1) {
            let j = Random.makeRandom(min: 0, max: count-1)
            swapAt(i, j)
        }
    }
}
