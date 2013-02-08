# Signals

Browser based Real Time Strategy.
Source code for hosted version from http://signals.herokuapp.com/

The project was created by Łukasz Koprowski, Piotr Bar, Robert Kruszewski

## Idea

What we wanted to create was a Civilization like gameplay. We were aware that you cannot recreate whole game in diffierent environment in just 3 weeks in 3 person group. We have introduced many simplifications over original so only the core remained. Although it is not fully playable it was a fun project to work on.

## Screenshots

![Initial Game](http://i.imgur.com/nVtnBCK.jpg)

![In game UI](http://i.imgur.com/XnXsdoi.jpg)

## Used Technologies

1. Easel.js (for canvas operations like drawing game board as well as UI)
2. Backbone.js (all elements apart from game board)
3. Underscore.js (for data manipulation)
4. Socket.io (communication)
5. Everyauth (social networks integration)
6. MongoDB with Mongoose (store for game results)
7. Redis (session store)
8. jQuery (provides DOM manipulation and more importantly jQuery.Deffered!)
9. Promised-io (server side promises library)

## Known Bugs

There are many. To name a few

1. Lobby isn't finished.
2. Game ending does not work as expected (try reaching end of the game to find out what happens)
3. There are synchronisation issues. (altough we have tried to eliminate as many during our tests still some of the persist)
4. There is no automated test suite.
5. Integration with social platforms is not completed. (especially Google+)

## Future Work

There will be no future work done on this project. What we have learned will be applied in our future creation. Which will be even more cutting edge and hopefully fully playable. Check my github repository soon to find out what we are working on.

## Disclaimer

This game was created for 2nd year trading game assingment at Imperial College London. The specification only requires that the submission is some type of a game.