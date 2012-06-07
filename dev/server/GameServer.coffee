_ = require('underscore')._
Types = require '../common/config/Types'

class GameServer

    constructor: ( @lobbyCommunicator ) ->
        @games = [
          {
            name: 'AwesomeGame'
            channel: 'channel1'
            type: Types.Games.FFA
            players: [
              [
                'me'
                'you'
                'someone'
                'someoneelse'
              ]
            ]
          }
          {
            name: 'UberAwesomeGame'
            channel: 'channel2'
            type: Types.Games.Team.Side2
            players: [
              [
                '37signals'
                'basecamp'
              ]
              [
                'Carsonified'
                'heroku'
              ]
            ]
          }
        ]

    newGame: ( gameName, gameType, player1 ) ->
      newGame =
        name: gameName
        channel: _.uniqueId 'channel-'
        type: gameType
        players: []
      @games.push newGame
      @lobbyCommunicator.emit 'game:new', newGame
      @joinGame gameName, player1

    joinGame: ( name, user ) ->


    getGames: ->
      JSON.stringify @games

module.exports = exports = GameServer
