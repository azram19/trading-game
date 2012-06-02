#node.js requirements
if require?
  _ = require 'underscore'
  Field = require '../objects/field'
  GameObject = require '../objects/object'
  ObjectState = require '../objects/state'
  ResourceBehaviour = require '../behaviours/ResourceBehaviour'

class Map
  fields: {} #level 0 on the map, resources and shit
  channels: {} #channels connecting fields

  constructor: ( @widthMin, @widthMax ) ->
    #initialize an empty map
    (
      @addField {}, x, y for x in [0...(@widthMin+y)]
    ) for y in [0..(@widthMax - @widthMin)]

    (
      @addField {}, x, y for x in [0...(2*@widthMax-y-@widthMin)]
    ) for y in [(@widthMax - @widthMin+1)...(2*(@widthMax - @widthMin ) + 1)]

    #generate fields
    initializeField = ( o, x, y ) ->
      field = new Field()
      #console.log x + " " + y + ":field"
      field

    #generate resources
    initializeResource = ( o, x, y ) ->
      chance = 0.42
      res = Math.random()

      if res < chance
        behaviour = new ResourceBehaviour ("money")
        resource = new GameObject behaviour, (new ObjectState())
        o.resource = resource
        #console.log x + " " + y + ":res"
        o
      else
        o

    @iterateFields initializeField
    @iterateFields initializeResource

  addField: ( field, x , y ) ->
    @fields[x] ?= {}
    @fields[x][y] = field

  addPlatform: ( platform, x, y ) ->
    platform.state.field = @fields[x][y]
    #console.log x + " " + y + " add pl"
    @fields[x][y].platform = platform

  #k - direction [0..6] clockwise from the top
  addChannel: ( channel, x, y, k ) ->
    @channels[x] ?= {}
    @channels[x][y] ?= {}
    @channels[x][y][k] = channel

  dump: ->
    print = ( o, x, y ) ->
      if o.resource.type?
        console.log x + " " + y + " res"
      if o.platform.type?
        console.log x + " " + y + " " + o.platform.type()
      o

    @iterateFields print


  getField: ( x, y ) ->
    if fields[x]?
      return fields[x][y]

    return null

  iterateFields: ( f ) =>
    (
      @fields[x][y] = f( @fields[x][y], x, y ) for x in [0...(@widthMin+y)]
    ) for y in [0..(@widthMax - @widthMin)]

    (
      @fields[x][y] = f( @fields[x][y], x, y ) for x in [0...(2*@widthMax-y-@widthMin)]
    ) for y in [(@widthMax - @widthMin+1)...(2*(@widthMax - @widthMin ) + 1)]

if module? and module.exports
  exports = module.exports = Map
else
  root['Map'] = Map
