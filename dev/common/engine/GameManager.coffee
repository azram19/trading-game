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
    @users = []
    @startPoints = []

  addPlayer: ( playerObject, point ) ->
    @users.push playerObject
    @startPoints.push point
    HQ = S.ObjectFactory.build S.Types.Entities.Platforms.HQ, @eventBus, playerObject
    [x,y] = point
    @map.addPlatform HQ, x, y
    console.log HQ
    HQ

  startGame: ->
    (
      [x,y] = point
      (@map.getField x, y).platform.produce()
    ) for point in @startPoints

    null

  getDimensions: ->
    [@map.minWidth, @map.maxWidth]

if module? and module.exports
  exports = module.exports = GameManager
else
  window.S.GameManager = GameManager
