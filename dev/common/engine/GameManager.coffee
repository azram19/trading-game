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

  startGame: ->
    @map.iterateFields ( o, x, y ) ->
      if o.platform.type?
        o.platform.trigger 'produce'
        o.platform.trigger 'route'
      for dir, channel of o.channels
        if channel?
          channel.trigger 'route'

  stopGame: ->
    @map.iterateFields ( o ) ->
      if o.resource.type? and o.resource.behaviour.PID
        clearInterval o.resource.behaviour.PID

  addHQ: ( HQ, position ) ->
    [x,y] = position
    @map.addPlatform HQ, x, y

  getDimensions: ->
    [@map.minWidth, @map.maxWidth]

if module? and module.exports
  exports = module.exports = GameManager
else
  window.S.GameManager = GameManager
