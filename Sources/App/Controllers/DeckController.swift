import Vapor
import HTTP

struct DeckController {
    
    let cardNames = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King", "Ace"]
    let suitNames = ["heart", "diamonds", "spades", "clubs"]
    
    func addRoutes(to drop: Droplet) {
        let deckGroup = drop.grouped("deck")
        
        let newDeckGroup = deckGroup.grouped("new")
        newDeckGroup.get("") { req in
            let deck = Deck(shuffle: false)
            try deck.save()
            try self.addCards(req.data["deckCount"]?.int, toDeck: deck)
            return deck
        }
        newDeckGroup.get("shuffle") { req in
            let deck = Deck(shuffle: true)
            try deck.save()
            try self.addCards(req.data["deckCount"]?.int, toDeck: deck)
            return deck
        }
        
        deckGroup.get(Deck.parameter) { req in
            let deck = try req.parameters.next(Deck.self)
            return deck
        }
    }
    
    
    func addCards(_ numDecks: Int?, toDeck deck: Deck) throws {
        var deckCount = 1
        if let decks = numDecks {
            deckCount = decks > 0 ? decks : 1
        }
        for x in 0..<(13 * deckCount)  {
            for suit in suitNames {
                let cardName = cardNames[x%13]
                print(cardName + suit)
                if let card = try Card.makeQuery().filter("suit", suit).filter("value", cardName).first() {
                    try deck.cards.add(card)
                    continue
                }
                let newCard = Card(value: cardName, suit: suit, deck: deck)
                try newCard.save()
                try deck.cards.add(newCard)
            }
        }
    }
}
