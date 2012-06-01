#node.js requirements
if require?
  _ = require 'underscore'
  Field = require '../objects/field'
  GameObject = require '../objects/object'
  HQBehaviour = require '../behaviours/HQBehaviour'
  ObjectState = require '../objects/state'
  Map = require './map'
  User = require '../models/user'

class gameManager
  #number of players
  #game state - map
  #user objects
  constructor: ( @users, startPoints, width, height ) ->
    createHQ = ( user ) ->
      stateHQ = new ObjectState user

      objectHQ = new GameObject( new HQBehaviour(), stateHQ )
      objectHQ

    console.log "Manager: initial HQ"
    HQs = (createHQ user for user in @users)

    console.log "Manager: create map"
    @map = new Map width, height

    console.log "Manager: configure map"
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

user1 = new User()
manager = new gameManager [user1], [[2,2]], 4, 6
