#node.js requirements
if require?
  _ = require 'underscore'
  Field = require '../objects/field'
  GameObject = require '../objects/object'
  HQBehaviour = require '../behaviours/HQBehaviour'
  ObjectState = require '../objects/state'
  Map = require './map'

class gameManager
  #number of players
  #game state - map
  #user objects
  construct: ( @users, startPoints ) ->
    createHQ = ( user ) ->
      stateHQ = new ObjectState user
      fieldHQ = new Field()

      objectHQ = new GameObject( new HQBehaviour(), stateHQ )

      fieldHQ.platform = objectHQ
      stateHQ.field = fieldHQ

      objectHQ

    HQs = createHQ user  for user in @users

    @map = new Map()
    @initialMapState( @map, HQs, startPoints )

  initialMapState: ( map, HQs, startPoints ) ->
    map.addField HQs[i], startPoints[i] for i in [0..HQs.length]

if exports?
  if module? and module.exports
    exports = module.exports = gameManager
else
  root['gameManager'] = gameManager
