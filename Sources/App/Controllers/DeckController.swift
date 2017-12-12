import Vapor
import HTTP

struct DeckController {
    
    let cardNames: [Character: String] = ["2":"2", "3":"3", "4":"4", "5":"5", "6":"6", "7":"7", "8":"8", "9":"9", "0":"10", "J":"Jack", "Q":"Queen", "K":"King", "A":"Ace"]
    let suitNames: [Character: String] = ["H":"hearts", "D":"diamonds", "S":"spades", "C":"clubs"]
    let cards = ["AS", "2S", "3S", "4S", "5S", "6S", "7S", "8S", "9S", "0S", "JS", "QS", "KS",
                 "AD", "2D", "3D", "4D", "5D", "6D", "7D", "8D", "9D", "0D", "JD", "QD", "KD",
                 "AC", "2C", "3C", "4C", "5C", "6C", "7C", "8C", "9C", "0C", "JC", "QC", "KC",
                 "AH", "2H", "3H", "4H", "5H", "6H", "7H", "8H", "9H", "0H", "JH", "QH", "KH"]
    
    func addRoutes(to drop: Droplet) {
        let deckGroup = drop.grouped("deck")
        
        let newDeckGroup = deckGroup.grouped("new")
        newDeckGroup.get("") { req in
            return try self.createDeck(shuffled: false, fromRequest: req)
        }
        newDeckGroup.get("shuffle") { req in
            return try self.createDeck(shuffled: true, fromRequest: req)
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
            for _ in 0..<drawCards {
                let card = deckCards.removeFirst()
                drawnCards.append(card)
                try card.delete()
            }
            
            return JSON(try Node(node: [
                "cards": try drawnCards.makeJSON(),
                "deckId": deck.id?.string ?? "",
                "remaining": try deck.cards.count()
                ]))
            
        }
        
        //FIXME: This is now broken
        deckGroup.get(Deck.parameter, "shuffle") { req in
            let deck = try req.parameters.next(Deck.self)
            deck.shuffled = true
            try deck.save()
            return deck
        }
    }
    
    func createDeck(shuffled: Bool, fromRequest req: Request) throws -> Deck  {
        let cards = req.data["cards"]?.string?.commaSeparatedArray()
        let deck = Deck(shuffle: shuffled)
        try deck.save()
        var numDecks = 1
        if let decks = req.data["deckCount"]?.int, decks > 0 {
            numDecks = decks
        }
        try self.addCards(numDecks, toDeck: deck, partialDeckCards: cards)
        return deck
    }
    
    
    func addCards(_ numDecks: Int, toDeck deck: Deck, partialDeckCards: [String]? = nil) throws {
        
        func addCard(withValue value: String, suit:String, toDeck deck:Deck) throws {
            let newCard = Card(value: value, suit: suit, deck: deck)
            try newCard.save()
        }
        
        if var partialDeck = partialDeckCards {
            if deck.shuffled {
                partialDeck.shuffle()
            }
            for cardAbreviation in partialDeck {
                guard let value = cardAbreviation.uppercased().first,
                    let suit = cardAbreviation.uppercased().last,
                    let cardValue = cardNames[value],
                    let cardSuit = suitNames[suit] else {
                    throw Abort.init(.badRequest, reason: "\(cardAbreviation) is not a valid card abreviation")
                }
                try addCard(withValue: cardValue, suit: cardSuit, toDeck: deck)
            }
        }
        else{
            var cardAbreviations = cards
            let numCards = cardAbreviations.count
            if deck.shuffled {
                cardAbreviations.shuffle()
            }
            for x in 0..<(numCards * numDecks) {
                let value = cardAbreviations[x%numCards].uppercased().first!
                let suit = cardAbreviations[x%numCards].uppercased().last!
                let cardValue = cardNames[value]!
                let cardSuit = suitNames[suit]!
                try addCard(withValue: cardValue, suit: cardSuit, toDeck: deck)
            }
        }
    }
    
}
