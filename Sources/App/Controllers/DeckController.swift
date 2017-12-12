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
            var numDecks = 1
            if let decks = req.data["deckCount"]?.int, decks > 0 {
                numDecks = decks
            }
            try self.addCards(numDecks, toDeck: deck)
            return deck
        }
        newDeckGroup.get("shuffle") { req in
            let deck = Deck(shuffle: true)
            try deck.save()
            var numDecks = 1
            if let decks = req.data["deckCount"]?.int, decks > 0 {
                numDecks = decks
            }
            try self.addCards(numDecks, toDeck: deck)
            return deck
        }
        
        deckGroup.get(Deck.parameter) { req in
            let deck = try req.parameters.next(Deck.self)
            return deck
        }
        
        deckGroup.get(Deck.parameter, "draw") { req in
            let deck = try req.parameters.next(Deck.self)
            var deckCards = try deck.cards.all()
            var drawCards = 1
            if let numCards = req.data["count"]?.int, numCards > 0 {
                drawCards = numCards
            }
            
            if drawCards > deckCards.count {
                throw Abort.init(.badRequest, reason: "Invalid number of cards to draw from this deck")
            }
            
            var drawnCards = [Card]()
            if deck.shuffled {
                deckCards.shuffle()
            }
            for _ in 0..<drawCards {
                let card = deckCards.removeFirst()
                drawnCards.append(card)
                try deck.cards.remove(card)
            }
            
            return JSON(try Node(node: [
                "cards": try drawnCards.makeJSON(),
                "deckId": deck.id?.string ?? "",
                "remaining": try deck.cards.count()
                ]))
            
        }
    }
    
    
    func addCards(_ numDecks: Int, toDeck deck: Deck) throws {
        for x in 0..<(13 * numDecks)  {
            for suit in suitNames {
                let cardName = cardNames[x%13]
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
