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
  #number of players
  #game state - map
  #user objects
  constructor: ( @users, startPoints, minWidth, maxWidth ) ->
    createHQ = ( user ) ->
      id = Math.random()
      ObjectFactory.build Types.Entities.HQ, user

    HQs = (createHQ user for user in @users)
    @nonUser = ObjectFactory.build Types.Entities.Player
    @map = new Map minWidth, maxWidth, @nonUser

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

if module? and module.exports
  exports = module.exports = GameManager
else
  window['GameManager'] = GameManager

#util = require 'util'

#user1 = ObjectFactory.build Types.Entities.User
#manager = new GameManager [user1], [[2,2]], 4, 6
#console.log (util.inspect manager.map, false, 50)
