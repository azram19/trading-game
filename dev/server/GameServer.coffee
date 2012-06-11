_ = require('underscore')._
Backbone = require 'backbone'
S = {}
S.Types = require '../common/config/Types'
S.ObjectFactory = require '../common/config/ObjectFactory'
S.Map = require '../common/engine/Map'
S.GameManager = require '../common/engine/GameManager'

class GameServer

  constructor: ->
    @games = {}
    @playersGame = {}
    @gameInstances = {}
    _.extend @, Backbone.Events

    @enforceAvailableGames()

  enforceAvailableGames: ->
    presentGames = _.chain(@games).map( (game) ->
      maxPlayers = game.typeData.numberOfSides * game.typeData.playersOnASide
      players = _.keys(game.players).length
      [game.type, maxPlayers is players]
    ).filter( (game) ->
      not game[1]
    ).map((game) ->
      game[0]
    ).value()
    (
      if not (type in presentGames)
        createdGame = @createGame type
        @games[createdGame.name] = createdGame
    ) for type, info of S.Types.Games.Info

  createGame: ( type ) ->
    id = _.uniqueId()
    game =
      name: 'game-' + id
      players: {}
      type: type
      typeData: S.Types.Games.Info[type]

  getGames: ->
    JSON.stringify @games

  getUserGame: ( userId ) ->
    @playersGame[userId]

  getGameInstance: ( name ) ->
    game = @games[name]
    instance = @gameInstances[name]
    if not (instance?)
      minWidth = game.typeData.minWidth
      maxWidth = game.typeData.maxWidth
      player = S.ObjectFactory.build S.Types.Entities.Player, 0
      map = new S.Map @, minWidth, maxWidth, player
      map.initialise()
      instance = new S.GameManager @, map
      @gameInstances[name] = instance
    @gameInstances[name]

  joinGame: ( name, user ) ->
    game = @games[name]
    if not (game.players[user]?)
      maxPlayers = game.typeData.numberOfSides * game.typeData.playersOnASide
      numberPlayers = _.keys(game.players).length
      if numberPlayers < maxPlayers
        console.log '[Game Server] user: ' + user + ' joined ' + name
        playerObject = S.ObjectFactory.build S.Types.Entities.Player, user
        position = game.typeData.startingPoints[numberPlayers]
        instance = @getGameInstance name
        game.players[user] =
          ready: false
          playerObject: playerObject
          position: position
        @playersGame[user] = game
        HQ = S.ObjectFactory.build S.Types.Entities.Platforms.HQ, @, playerObject
        @.trigger 'player:joined', game.name, playerObject, position, HQ.state
        @.trigger 'update:lobby:game', @games[name]
        instance.addPlayer playerObject, position
        instance.addHQ HQ, position

  setUserReady: ( userId ) ->
    game = @getUserGame userId
    maxPlayers = game.typeData.numberOfSides * game.typeData.playersOnASide
    game.players[userId].ready = true
    if _.keys(game.players).length is maxPlayers
      if _.all _.pluck( game.players, 'ready' ), _.identity
        @startGame game.name

  startGame: ( name ) ->
    @.trigger 'all:ready', game.channel
    instance = @getGameInstace name
    instance.startGame()

module.exports = exports = GameServer
