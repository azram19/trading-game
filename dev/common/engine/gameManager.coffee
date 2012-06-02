#node.js requirements
if require?
  _ = require 'underscore'
  Field = require '../objects/field'
  ObjectFactory = require '../config/ObjectFactory'
  Types = require '../config/Types'
  Map = require './map'

class gameManager
  #number of players
  #game state - map
  #user objects
  constructor: ( @users, startPoints, minWidth, maxWidth ) ->
    createHQ = ( user ) ->
      id = Math.random()
      ObjectFactory.build Types.Entities.HQ, user

    HQs = (createHQ user for user in @users)
    @nonUser = ObjectFactory.build Types.Entities.User
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
  exports = module.exports = gameManager
else
  root['gameManager'] = gameManager

util = require 'util'

user1 = ObjectFactory.build Types.Entities.User
manager = new gameManager [user1], [[2,2]], 4, 6
#console.log (util.inspect maconfignager.map, false, 50)
