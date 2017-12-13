import Vapor
import FluentProvider
import HTTP

final class Card: Model {
    
    let storage = Storage()
//    static let idType: IdentifierType = .custom(String)
    
    // MARK: Properties and database keys
    
    var value: String
    var suit: String
    var deckId: Identifier?
    var code: String
    
    struct Keys {
        static let id = "id"
        static let value = "value"
        static let suit = "suit"
        static let code = "code"
    }

    init(value: String, suit: String, deck: Deck) {
        self.value = value
        self.suit = suit
        self.deckId = deck.id
        var v = value.uppercased().first!
        if v == "1" {
            v = "0"
        }
        self.code = "\(v)\(suit.uppercased().first!)"
    }

    // MARK: Fluent Serialization

    init(row: Row) throws {
        value = try row.get(Card.Keys.value)
        suit = try row.get(Card.Keys.suit)
        deckId = try row.get(Deck.foreignIdKey)
        code = try row.get(Card.Keys.code)
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Card.Keys.value, value)
        try row.set(Card.Keys.suit, suit)
        try row.set(Deck.foreignIdKey, deckId)
        try row.set(Card.Keys.code, code)
        return row
    }
}

// MARK: Fluent Preparation

extension Card: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(Card.Keys.value)
            builder.string(Card.Keys.suit)
            builder.parent(Deck.self)
        }
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

// MARK: JSON

extension Card: JSONConvertible {
    convenience init(json: JSON) throws {
        let deckId: Identifier = try json.get("userId")
        guard let deck = try Deck.find(deckId) else {
            throw Abort.badRequest
        }
        self.init(
            value: try json.get(Card.Keys.value),
            suit: try json.get(Card.Keys.suit),
            deck: deck
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Card.Keys.id, id)
        try json.set(Card.Keys.value, value)
        try json.set(Card.Keys.suit, suit)
        try json.set(Card.Keys.code, code)
        return json
    }
}

// MARK: HTTP

extension Card: ResponseRepresentable { }

