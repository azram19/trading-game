_ = require('underscore')._
Types = require '../common/config/Types'

class GameServer

    constructor: ( @lobbyCommunicator ) ->
        @typesConfig = []

        @games = [
          {
            name: 'AwesomeGame'
            channel: 'channel1'
            type: Types.Games.FFA
            typeData: @getGameTypeData Types.Games.FFA
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
            typeData: @getGameTypeData Types.Games.Team.Side2
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

    getGameTypeData: ( type ) ->
      #@typesConfig[type]

      {
        name: 'Team Match'
        numberOfSides: 2
        playersOnASide: 3
        teams: true
      }

    getGames: ->
      JSON.stringify @games

module.exports = exports = GameServer
