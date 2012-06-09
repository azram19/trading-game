_ = require('underscore')._
Backbone = require 'backbone'
S = {}
S.Types = require '../common/config/Types'

class GameServer

  constructor: ->
    @games = []
    _.extend @, Backbone.Events

    @enforceAvailableGames()

  enforceAvailableGames: ->
    presentGames = _.chain(@games).map( (game) ->
      maxPlayers = game.typeData.numberOfSides * game.typeData.playersOnASide
      players = _.flatten(game.players).length
      [game.type, maxPlayers is players]
    ).filter( (game) ->
      not game[1]
    ).map((game) ->
      game[0]
    ).value()
    (
      if not (type in presentGames)
        @games.push @createGame(type)
    ) for type, info of S.Types.Games.Info
    @.trigger 'update:games', @games

  createGame: ( type ) ->
    id = _.uniqueId()
    game =
      name: 'game-' + id
      channel: 'channel-' + id
      players: []
      type: type
      typeData: S.Types.Games.Info[type]

  joinGame: ( name, user ) ->

  getGames: ->
    JSON.stringify @games

module.exports = exports = GameServer
