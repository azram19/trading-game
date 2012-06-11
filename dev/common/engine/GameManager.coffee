#node.js requirements
S = {}
if require?
  _ = require 'underscore'
  S.Field = require '../objects/Field'
  S.ObjectFactory = require '../config/ObjectFactory'
  S.Types = require '../config/Types'
  S.Map = require './Map'
else
  _ = window._
  S.Field = window.S.Field
  S.ObjectFactory = window.S.ObjectFactory
  S.Types = window.S.Types
  S.Map = window.S.Map

class GameManager

  constructor: ( @eventBus, @map ) ->
    @players = {}
    @startingPoints = {}

  addPlayer: ( playerObject, position ) ->
    @players[playerObject.id] = playerObject
    @startingPoints[playerObject.id] = position
    console.log @players, @startingPoints

  startGame: ->
    (
      [x,y] = point
      (@map.getField x, y).platform.produce()
    ) for point in @startingPoints

    null

  addHQ: ( HQ, position ) ->
    [x,y] = position
    @map.addPlatform HQ, x, y

  getDimensions: ->
    [@map.minWidth, @map.maxWidth]

if module? and module.exports
  exports = module.exports = GameManager
else
  window.S.GameManager = GameManager
