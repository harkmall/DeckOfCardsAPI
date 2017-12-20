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
        
        deckGroup.get(Deck.parameter, "shuffle") { req in
            let deck = try req.parameters.next(Deck.self)
            deck.shuffled = true
            try deck.save()
            
            let cards = try deck.cards.all()
            let cardsInDeck = cards.map { $0.code }
            
            for card in cards {
                try card.delete()
            }
            
            try self.addCards(cardsInDeck, toDeck: deck)
            return deck
        }
        
        deckGroup.get(Deck.parameter, "pile", Pile.parameter, "add") { req in
            let deck = try req.parameters.next(Deck.self)
            guard let name = req.parameters["pile_Id"]?.string, let cards = req.data["cards"]?.string?.commaSeparatedArray() else {
                throw Abort.badRequest
            }
            
            var pile: Pile
            if let existingPile = try deck.piles.filter("name", .equals, name).first() {
                pile = existingPile
            }
            else{
                pile = Pile(name: name, deck: deck)
                try pile.save()
            }
            
            let deckCards = try deck.cards.all()
            
            guard Set(cards).isSubset(of: Set(deckCards.map{ $0.code }) ) else {
                throw Abort.init(.badRequest, reason: "Can't add cards to a pile that aren't in the deck!")
            }
            
            let cardsToMoveToPile = deckCards.filter { cards.contains($0.code) }
            for card in cardsToMoveToPile {
                card.deckId = nil
                card.pileId = pile.id
                try card.save()
            }
            
            return deck
        }
        
        deckGroup.get(Deck.parameter, "pile", Pile.parameter, "draw") { req in
            let deck = try req.parameters.next(Deck.self)
            guard let name = req.parameters["pile_Id"]?.string else {
                throw Abort.badRequest
            }
            
            guard let pile = try deck.piles.filter("name", .equals, name).first() else {
                throw Abort.init(.notFound, reason: "Pile with the name \(name) doesn't exist on this deck." )
            }
            
            var drawnCards = [Card]()
            var pileCards = try pile.cards.all()
            
            if let cards = req.data["cards"]?.string?.commaSeparatedArray() {
                guard Set(cards).isSubset(of: Set(pileCards.map{ $0.code }) ) else {
                    throw Abort.init(.badRequest, reason: "Can't draw cards from a pile that aren't in the pile!")
                }
                for card in pileCards.filter({ cards.contains($0.code) }) {
                    drawnCards.append(card)
                    card.pileId = nil
                    try card.save()
                }
            }
            else {
                var drawCount = 1
                if let count = req.data["count"]?.int, count > 1 {
                    drawCount = count
                }
                guard drawCount <=  pileCards.count else {
                    throw Abort.init(.badRequest, reason: "Can't draw \(drawCount) cards from a pile that only has \(pileCards.count) cards!")
                }
                
                for _ in 0..<drawCount  {
                    let card = pileCards.removeFirst()
                    drawnCards.append(card)
                    card.pileId = nil
                    try card.save()
                }
            }
            
            return try self.pileJSON(fromDeck: deck, cards: drawnCards)
        }
        
        deckGroup.get(Deck.parameter, "pile", Pile.parameter, "draw", "bottom") { req in
            let deck = try req.parameters.next(Deck.self)
            guard let name = req.parameters["pile_Id"]?.string else {
                throw Abort.badRequest
            }
            
            guard let pile = try deck.piles.filter("name", .equals, name).first() else {
                throw Abort.init(.notFound, reason: "Pile with the name \(name) doesn't exist on this deck." )
            }
            var pileCards = try pile.cards.all()
            let bottomCard = pileCards.removeLast()
            bottomCard.pileId = nil
            try bottomCard.save()
            
            return try self.pileJSON(fromDeck: deck, cards: [bottomCard])
        }
        
    }
    
    func pileJSON(fromDeck deck:Deck, cards: [Card]) throws -> JSON {
        return JSON(try Node(node:[
            "deckId": (deck.id?.string)!,
            "cards": try cards.makeJSON()
            ]))
    }
    
    func createDeck(shuffled: Bool, fromRequest req: Request) throws -> Deck  {
        var cardsToAdd = cards
        if let cards = req.data["cards"]?.string?.commaSeparatedArray() {
            cardsToAdd = cards
        }
        let deck = Deck(shuffle: shuffled)
        try deck.save()
        if let decks = req.data["deckCount"]?.int, decks > 1 {
            var multiDeckCards = [String]()
            
            for x in 0..<(cardsToAdd.count * decks) {
                multiDeckCards.append(cardsToAdd[x%cardsToAdd.count])
            }
            cardsToAdd = multiDeckCards
        }
        try self.addCards(cardsToAdd, toDeck: deck)
        return deck
    }
    
    func addCards(_ cards: [String], toDeck deck: Deck) throws {
        
        var cardsToAdd = cards
        if deck.shuffled {
            try cardsToAdd.shuffle()
        }
        for cardAbreviation in cardsToAdd {
            guard let value = cardAbreviation.uppercased().first,
                let suit = cardAbreviation.uppercased().last,
                let cardValue = cardNames[value],
                let cardSuit = suitNames[suit] else {
                    throw Abort.init(.badRequest, reason: "\(cardAbreviation) is not a valid card abreviation")
            }
            let newCard = Card(value: cardValue, suit: cardSuit, deck: deck)
            try newCard.save()
        }
    }
    
}

extension DeckController: EmptyInitializable { }

