# DeckOfCardsAPI
[![Twitter: @KrauseFx](https://img.shields.io/badge/contact-@SoftieEng-blue.svg?style=flat)](https://twitter.com/softieeng)
[![License](https://img.shields.io/badge/license-BSD-green.svg?style=flat)](https://github.com/harkmall/MHSegmentedControl/blob/master/LICENSE)

## How to run this

This runs on [Vapor](https://github.com/vapor/vapor) so you'll have to have that all set up before you do anything.

Once you've got that done, run a quick

```
vapor update
vapor build
vapor xcode -y
```
To update the swift packages, build the project, generate the xcode project and open it. 😅 



### //TODO
- [x] Implement Shuffle (Shuffle doesn't maintain shuffled state, every time you request the deck again, it will get reshuffled. Probably not good, will look into that later.)

~~Change Deck-Cards relationship to Siblings instead of Parent-Child~~

~~Once done, make it so there are only ever 52 Cards in the DB and just reference them from different Decks~~
Decided against this again, was too hard to maintain the shuffled order of a deck. So every deck that gets created creates new objects for each of its cards. Not ideal, but ¯\\_(ツ)_/¯
- [x] Implement drawing cards
- [x] Implement Partial Deck
- [x] Implement Piles
- [x] Implement drawing from piles
- [ ] Make a website for this

