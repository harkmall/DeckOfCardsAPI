# DeckOfCardsAPI

### //TODO
- [x] Implement Shuffle (Shuffle doesn't maintain shuffled state, every time you request the deck again, it will get reshuffled. Probably not good, will look into that later.)

~~- [x] Change Deck-Cards relationship to Siblings instead of Parent-Child~~

~~- [x] Once done, make it so there are only ever 52 Cards in the DB and just reference them from different Decks~~
Decided against this again, was too hard to maintain the shuffled order of a deck. So every deck that gets created creates new objects for each of its cards. Not ideal, but ¯\\_(ツ)_/¯
- [x] Implement drawing cards
- [x] Implement Partial Deck
- [ ] Make a website for this

