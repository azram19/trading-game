#node.js requirements
if require?
  _ = require 'underscore'
  Field = require '../objects/field'
  ObjectFactory = require '../config/ObjectFactory'
  Types = require '../config/Types'

class Map
  #fields: {} #level 0 on the map, resources and shit
  #channels: {} #channels connecting fields

  constructor: ( @minWidth, @maxWidth, @nonUser ) ->
    @fields = {}
    @channles = {}
    @diffRows = @maxWidth - @minWidth
    #initialize an empty map
    for y in [0 ... (2*@diffRows + 1)]
        for x in [0 ... @maxWidth - Math.abs(@diffRows - y)]
            @addField {}, y, x

    #generate fields
    initializeField = ( o, y, x ) ->
      field = new Field()
      #console.log x + " " + y + ":field"
      field

    #generate resources
    initializeResource = ( o, y, x ) =>
      chance = 0.42
      res = Math.random()

      if res < chance
        kind = ''
        if res > 0.5
            kind = Types.Resources.Metal
        else
            kind = Types.Resources.Tritium
        resource = ObjectFactory.build kind, @nonUser
        resource.state.field = o
        o.resource = resource
        o
      else
        o

    @iterateFields initializeField
    @iterateFields initializeResource

  addField: ( field, y, x ) ->
    @fields[y] ?= {}
    @fields[y][x] = field

  addPlatform: ( platform, y, x ) ->
    platform.state.field = @fields[y][x]
    #console.log x + " " + y + " add pl"
    @fields[y][x].platform = platform

  #k - direction [0..6] clockwise from the top
  addChannel: ( channel, y, x, k ) ->
    @channels[y] ?= {}
    @channels[y][x] ?= {}
    @channels[y][x][k] = channel

  dump: ->
    print = ( o, y, x ) ->
      if o.resource.type?
        console.log x + " " + y + " res"
      if o.platform.type?
        console.log x + " " + y + " " + o.platform.type()
      o

    @iterateFields print


  getField: ( x, y ) ->
    if fields[y]?
      return fields[y][x]

    return null

  iterateFields: ( f ) =>
    for y in [0 ... (2*@diffRows + 1)]
        for x in [0 ... @maxWidth - Math.abs(@diffRows - y)]
            @fields[y][x] = f( @fields[y][x], y, x )

if module? and module.exports
  exports = module.exports = Map
else
  window['Map'] = Map
