_ = require('underscore')._
Backbone = require 'backbone'
S = {}
S.Types = require '../common/config/Types'
S.ObjectFactory = require '../common/config/ObjectFactory'
S.Map = require '../common/engine/Map'
S.GameManager = require '../common/engine/GameManager'

class GameServer

  constructor: ->
    @startingPoints = [[2,2],[6,12],[4,4],[8,8],[4,14],[7,10],[2,12],[7,3]]
    @games = {}
    @instances = {}
    @playersGames = {}
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
      channel: 'channel-' + id
      players: []
      type: type
      typeData: S.Types.Games.Info[type]

  getUserGame: ( userId ) ->
    @playersGames[userId]

  getGameInstance: ( name ) ->
    if not (@instances[name]?)
      player = S.ObjectFactory.build S.Types.Entities.Player, 0
      map = new S.Map @, 8, 15, player
      map.initialise()
      @instances[name] = new S.GameManager @, map
    @instances[name]

  joinGame: ( name, user ) ->
    game = @games[name]
    if not (game.players[user]?)
      maxPlayers = game.typeData.numberOfSides * game.typeData.playersOnASide
      numberPlayers = _.keys(game.players).length
      if numberPlayers < maxPlayers
        game.players[user] =
          ready: false
        instance = @getGameInstance name
        playerObject = S.ObjectFactory.build S.Types.Entities.Player, user
        position = @startingPoints[numberPlayers]
        HQ = instance.addPlayer playerObject, position
        @playersGames[user] = @games[name]
        console.log '[Game Server] user: ' + user + ' joined ' + name
        @.trigger 'player:joined', game.channel, playerObject, position, HQ
        @.trigger 'update:lobby:game', @games[name]

  getGames: ->
    JSON.stringify @games

  setUserReady: ( userId ) ->
    game = @getUserGame userId
    maxPlayers = game.typeData.numberOfSides * game.typeData.playersOnASide
    game.players[userId].ready = true
    if _.keys(game.players).length is maxPlayers
      if _.all _.values(game.players), _.identity
        @startGame game.name

  startGame: ( name ) ->
    @.trigger 'all:ready', game.channel
    instance = @getGameInstace name
    instance.startGame()

module.exports = exports = GameServer
