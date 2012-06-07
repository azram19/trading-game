#node.js requirements
if require?
  _ = require 'underscore'
  Field = require '../objects/Field'
  ObjectFactory = require '../config/ObjectFactory'
  Types = require '../config/Types'
else
  _ = window._
  Field = window.Field
  ObjectFactory = window.ObjectFactory
  Types = window.Types

class Map

  constructor: ( @eventBus, @minWidth, @maxWidth, @nonUser ) ->
    @fields = {}
    @diffRows = @maxWidth - @minWidth
    @directionModificators =
      0: [-1, -1]
      1: [1, -1]
      2: [1, 0]
      3: [1, 1]
      4: [-1, 1]
      5: [-1, 0]

    #initialize an empty map
    for y in [0 ... (2*@diffRows + 1)]
        for x in [0 ... @maxWidth - Math.abs(@diffRows - y)]
            @addField {}, x, y

    #generate fields
    initializeField = ( o, x, y ) ->
      field = new Field(x, y)
      #console.log x + " " + y + ":field"
      field

    #generate resources
    initializeResource = ( o, x, y ) =>
      chance = 0.42
      res = Math.random()

      if res < chance
        kind = ''
        if res > chance / 2
            kind = Types.Resources.Metal
        else
            kind = Types.Resources.Tritium
        resource = ObjectFactory.build kind, @eventBus, @nonUser
        resource.state.field = o
        o.resource = resource
        o
      else
        o

    @iterateFields initializeField
    @iterateFields initializeResource

  addField: ( field, x, y ) ->
    @fields[y] ?= {}
    @fields[y][x] = field

  addPlatform: ( platform, x, y ) ->
    platform.state.field = @fields[y][x]
    #console.log x + " " + y + " add pl"
    @fields[y][x].platform = platform

  #k - direction [0..6] clockwise from the top
  addChannel: ( channel, x, y, k ) ->
    @fields[y] ?= {}
    @fields[y][x].channels ?= {}
    channel.state.field = @fields[y][x]
    channel.state.direction = k
    @fields[y][x].channels[k] = channel
    [mX, mY] = @directionModificators[k]
    nY = y + mY
    nX = x + mX
    @fields[nY] ?= {}
    @fields[nY][nX].channels ?= {}
    @fields[nY][nX].channels[(k+3)%6] = channel


  dump: ->
    print = ( o, x, y ) ->
      if o.resource.type?
        console.log x + " " + y + " res"
      if o.platform.type?
        console.log x + " " + y + " " + o.platform.type()
      o

    @iterateFields print

  getChannel: (x, y, k) ->
    field = @getField y, x
    if field?
      return field.channels[k]
    else
      null

  getField: ( x, y ) ->
    if @fields[y]?
      return @fields[y][x]

    return null

  iterateFields: ( f ) =>
    for y in [0 ... (2*@diffRows + 1)]
        for x in [0 ... @maxWidth - Math.abs(@diffRows - y)]
            @fields[y][x] = f( @fields[y][x], x, y )

if module? and module.exports
  exports = module.exports = Map
else
  window['Map'] = Map
