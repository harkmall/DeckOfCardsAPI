# DeckOfCardsAPI

[![Twitter: @SoftieEng](https://img.shields.io/badge/contact-@SoftieEng-blue.svg?style=flat)](https://twitter.com/softieeng)
[![License](https://img.shields.io/badge/license-BSD-green.svg?style=flat)](https://github.com/harkmall/MHSegmentedControl/blob/master/LICENSE)

**It's ALIVE: the api is alive and running: [https://deckofcards.vapor.cloud/](https://deckofcards.vapor.cloud/) 🤘🏻**

**Disclaimer: I had to take the databse off of the API cause it was costing $$, so this may or may not still work**

## How to run this

This runs on [Vapor](https://github.com/vapor/vapor) so you'll have to have that all set up before you do anything.

Once you've got that done, run a quick

```
vapor update
vapor build
vapor xcode -y
```

To update the swift packages, build the project, generate the xcode project and open it. 😅 Then you should be able to just give'r and start writing some codes.

You'll also need to add a `mongo.json` file to the Config folder, mines .gitignored 😉. It should look like this:

```
{
    "url": "<mongoURL>"
}
```

> Major 🔑: If you want to keep yours a secret like I did, make a new folder inside the Config folder called `secrets` and everything in there will get .gitignored

### //TODO

* [x] Implement Shuffle (Shuffle doesn't maintain shuffled state, every time you request the deck again, it will get reshuffled. Probably not good, will look into that later.)

* [x] ~~Change Deck-Cards relationship to Siblings instead of Parent-Child~~

* [x] ~~Once done, make it so there are only ever 52 Cards in the DB and just reference them from different Decks~~
      Decided against this again, was too hard to maintain the shuffled order of a deck. So every deck that gets created creates new objects for each of its cards. Not ideal, but ¯\\_(ツ)_/¯
* [x] Implement drawing cards
* [x] Implement Partial Deck
* [x] Implement Piles
* [x] Implement drawing from piles
* [x] Make a website for this
* [x] Figure out how to host this on vapor without having my DB credentials public
* [x] make something that will delete all the cards in decks that havent been used in X days
