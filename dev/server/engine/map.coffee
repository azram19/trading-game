#node.js requirements
if require?
  _ = require 'underscore'
  Field = require '../objects/field'
  GameObject = require '../objects/object'
  ResourceBehaviour = require '../behaviours/ResourceBehaviour'

class Map
  fields: {} #level 0 on the map, resources and shit
  channels: {} #channels connecting fields

  constructor: ( @widthMin, @widthMax ) ->
    #initialize an empty map
    (
      addField {}, x, y for x in [0...(@widthMin+y)]
    ) for y in [0..(@widthMax - @widthMin)]

    (
      addField {}, x, y for x in [0...(@widthMin+y)]
    ) for y in [(@widthMax - @widthMin )..0]

    #generate fields
    initializeField = ( o, x, y ) ->
      field = new Field()

      field

    #generate resources
    initializeResource = ( o, x, y ) ->
      chance = 0.3
      res = Math.random()

      if res < chance
        resource = new GameObject new ResourceBehaviour()
        o.resource = resource
      else
        o

    iterateFields initializeField
    iterateFields initializeResource

  addField: ( field, x , y ) ->
    @fields[x] ?= {}
    @fields[x][y] = field

  #k - direction [0..6] clockwise from the top
  addChannel: ( channel, x, y, k ) ->
    @channels[x] ?= {}
    @channels[x][y] ?= {}
    @channels[x][y][k] = channel

  getField: ( x, y ) ->
    if fields[x]?
      return fields[x][y]

    return null

  iterateFields: ( f ) =>
    (
      @fields[x][y] = f( @fields[x][y], x, y ) for x in [0...(@widthMin+y)]
    ) for y in [0..(@widthMax - @widthMin)]

    (
      @fields[x][y] = f( @fields[x][y], x, y ) for x in [0...(@widthMin+y)]
    ) for y in [(@widthMax - @widthMin )..0]

if exports?
  if module? and module.exports
    exports = module.exports = Map
else
  root['Map'] = Map
