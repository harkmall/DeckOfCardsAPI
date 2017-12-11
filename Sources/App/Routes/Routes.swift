import Vapor

extension Droplet {
    func setupRoutes() throws {
        let deckController = DeckController()
        deckController.addRoutes(to: self)
    }
}
