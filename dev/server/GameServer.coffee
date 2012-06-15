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

  getUIDimensions: ( name ) ->
    game = @games[name]
    margin = S.Types.UI.Margin
    size = S.Types.UI.Size
    maxRow = game.typeData.maxWidth
    horIncrement = Math.ceil Math.sqrt(3)*S.Types.UI.Size/2
    verIncrement = Math.ceil 3*S.Types.UI.Size/2
    diffRows = game.typeData.maxWidth - game.typeData.minWidth
    distance = 2*horIncrement
 
    x = 2*(margin-horIncrement) + maxRow * distance + margin
    y = (margin+size) + (diffRows * 2 + 1) * verIncrement + margin
    [x, y]

  getGameInstance: ( name ) ->
    game = @games[name]
    instance = @gameInstances[name]
    if not (instance?)
      console.log '[GameServer] game created - ', name
      minWidth = game.typeData.minWidth
      maxWidth = game.typeData.maxWidth
      player = S.ObjectFactory.build S.Types.Entities.Player, 0
      map = new S.Map @, minWidth, maxWidth, player, game.typeData.startingPoints
      instance = new S.GameManager @, map
      instance.map.initialise()
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
        @trigger 'player:joined', game.name, playerObject, position, HQ.state
        @trigger 'update:lobby:game', @games[name]
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
    @trigger 'all:ready', name
    @getGameInstance(name).startGame()

  directionGet: (user, x1, y1, x2, y2) ->
    game = @playersGame[user.userId]
    instance = @getGameInstance(game.name)
    instance.map.directionGet x1, y1, x2, y2

  nonUserId: ( user ) ->
    game = @playersGame[user.userId]
    instance = @getGameInstance(game.name)
    instance.map.nonUser.id

  buildChannel: ( game, x, y, k, owner ) ->
    instance = @gameInstances[game]
    channel = S.ObjectFactory.build S.Types.Entities.Channel, @, owner
    instance.map.addChannel channel, x, y, k
    @trigger 'channel:built', game, x, y, k, owner

  buildPlatform: ( game, x, y, type, owner ) ->
    platform = S.ObjectFactory.build S.Types.Entities.Platforms.Normal, @, owner, type
    @gameInstances[game].map.addPlatform platform, x, y
    platform.trigger 'produce'
    @trigger 'platform:built', game, x, y, type, owner

  setRouting: ( game, x, y, routing, owner ) ->
    instance = @gameInstances[game]
    field = instance.map.getField x, y
    _.extend field.platform.state.routing, routing
    @trigger 'routing:changed', game, x, y, routing, owner

module.exports = exports = GameServer
