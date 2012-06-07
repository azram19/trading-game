#node.js requirements
if require?
  _ = require 'underscore'
  Field = require '../objects/Field'
  ObjectFactory = require '../config/ObjectFactory'
  Types = require '../config/Types'
  Map = require './Map'
else
  _ = window._
  Field = window.Field
  ObjectFactory = window.ObjectFactory
  Types = window.Types
  Map = window.Map

class GameManager

  constructor: ( @eventBus, @users, startPoints, minWidth, maxWidth ) ->
    createHQ = ( user ) =>
      id = Math.random()
      ObjectFactory.build Types.Entities.HQ, @eventBus, user

    HQs = (createHQ user for user in @users)
    @nonUser = ObjectFactory.build Types.Entities.Player
    @map = new Map @eventBus, minWidth, maxWidth, @nonUser

    @initialMapState( @map, HQs, startPoints )
    #@map.dump()

    (
      HQ.produce()
    ) for HQ in HQs

    null

  initialMapState: ( map, HQs, startPoints ) ->
    (
      [x,y] = startPoints[i]
      map.addPlatform HQs[i], x, y
    ) for i in [0...HQs.length]

  getDimensions: ->
    [@map.minWidth, @map.maxWidth]

if module? and module.exports
  exports = module.exports = GameManager
else
  window['GameManager'] = GameManager
