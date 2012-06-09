#node.js requirements
S = {}
if require?
  _ = require 'underscore'
  S.Field = require '../objects/Field'
  S.ObjectFactory = require '../config/ObjectFactory'
  S.Types = require '../config/Types'
else
  _ = window._
  S.Field = window.S.Field
  S.ObjectFactory = window.S.ObjectFactory
  S.Types = window.S.Types

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
      field = new S.Field(x, y)
      #console.log x + " " + y + ":field"
      field

    #generate resources
    initializeResource = ( o, x, y ) =>
      chance = 0.42
      res = Math.random()

      if res < chance
        kind = ''
        if res > chance / 2
            kind = S.Types.Resources.Metal
        else
            kind = S.Types.Resources.Tritium
        resource = S.ObjectFactory.build kind, @eventBus, @nonUser
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
    @fields[y][x].platform = platform
    #console.log x + " " + y + " add pl"
    (
      console.log channel
      nDir = (+dir + 3) % 6
      console.log dir, nDir
      platform.state.routing[dir].object = channel
      channel.state.routing[nDir].object = platform
    ) for dir, channel of @fields[y][x].channels

  #k - direction [0..5] clockwise from the top
  addChannel: ( channel, x, y, k ) ->
    @fields[y] ?= {}
    @fields[y][x].channels ?= {}
    channel.state.field = @fields[y][x]
    channel.state.direction = k
    @fields[y][x].channels[k] = channel
    [mX, mY] = @directionModificators[k]
    nY = y + mY
    nX = x + mX
    nK = (k + 3) % 6
    @addReverseChannel channel, nX, nY, nK
    # Bind channel to routing table
    routingAddChannel = (x, y, k) =>
      if @fields[y][x].platform.type?
        nK = (k + 3) % 6
        @fields[y][x].platform.state.routing[k].object = channel
        channel.state.routing[nK].object = @fields[y][k].platform

    routingAddChannel x, y, k
    routingAddChannel nX, nY, nK

  addReverseChannel: ( channel, x, y, k ) ->
    @fields[y] ?= {}
    @fields[y][x].channels ?= {}
    @fields[y][x].channels[k] = channel

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
  window.S.Map = Map
