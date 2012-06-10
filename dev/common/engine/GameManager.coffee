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

  initialMapState: ( startPoints ) ->
    createHQ = ( user ) =>
      id = Math.random()
      S.ObjectFactory.build S.Types.Entities.Platforms.HQ, @eventBus, user

    HQs = (createHQ user for user in @users)
    (
      [x,y] = startPoints[i]
      @map.addPlatform HQs[i], x, y
    ) for i in [0...HQs.length]

    (
      HQ.produce()
    ) for HQ in HQs

    null

  getDimensions: ->
    [@map.minWidth, @map.maxWidth]

if module? and module.exports
  exports = module.exports = GameManager
else
  window.S.GameManager = GameManager
