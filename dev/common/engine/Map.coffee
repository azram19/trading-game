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
    @directionModUpper = [[-1, -1], [0, -1], [1, 0], [1, 1], [0, 1], [-1, 0]]
    @directionModLower = [[0, -1], [1, -1], [1, 0], [0, 1], [-1, 1], [-1, 0]]
    #initialize an empty map
    for y in [0 ... (2*@diffRows + 1)]
        for x in [0 ... @maxWidth - Math.abs(@diffRows - y)]
            @addField {}, x, y

    #generate fields
    initializeField = ( o, x, y ) =>
      @fields[y][x] = new S.Field(x, y)
      #console.log x + " " + y + ":field"

    @iterateFields initializeField

  initialise: ->
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
        @addResource resource, x, y

    @iterateFields initializeResource

  directionModificators: (x, y, dir) ->
    if y < @diffRows or (y is @diffRows and dir < 3)
      mod = @directionModUpper[dir]
    else if y > @diffRows or (y is @diffRows and dir >= 3)
      mod = @directionModLower[dir]
    [x + mod[0], y + mod[1]]

  addField: ( field, x, y ) ->
    @fields[y] ?= {}
    @fields[y][x] = field

  addResource: ( resource, x, y ) ->
    resource.behaviour.events = @eventBus
    resource.state.field = @fields[y][x]
    @fields[y][x].resource = resource

  addPlatform: ( platform, x, y ) ->
    platform.behaviour.events = @eventBus
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
    channel.behaviour.events = @eventBus
    @fields[y] ?= {}
    @fields[y][x].channels ?= {}
    channel.state.field = @fields[y][x]
    channel.state.direction = k
    @fields[y][x].channels[k] = channel
    [nX, nY] = @directionModificators x, y, k
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
    #if not (@getField(nX, nY).owner?)
      #@eventBus.trigger("owner:channel", [nX, nY], channel.state.owner)

  addReverseChannel: ( channel, x, y, k ) ->
    @fields[y] ?= {}
    @fields[y][x].channels ?= {}
    @fields[y][x].channels[k] = channel

  extractGameState: ->
    gameState = {}
    @iterateFields (field, x, y) =>
      gameState[y] ?= {}
      channels = {}
      if _.keys(field.channels).length > 0
        channels = _.pluck field.channels, 'state'
        (
          channel = @clearRoutingObjects channel
          channel.field = {}
        ) for channel in channels
      platform = {}
      if field.platform.type?
        platform =  @clearRoutingObjects field.platform.state
        platform.field = {}
      resource = {}
      if field.resource.type?
        resource = field.resource.state
        resource.field = {}
      exportState =
        channels: channels
        platform: platform
        resource: resource
      gameState[y][x] = exportState
    gameState

  clearRoutingObjects: (state) ->
    if state?
      (
       route.object = {}
      ) for route in state.routing
    state

  importGameState: ( gameState ) ->
    @iterateFields ( field, x, y ) =>
      field = gameState[y][x]
      #console.log x, y
      if field.platform.id?
        #console.log 'platform'
        platform = S.ObjectFactory.build field.platform.type, @eventBus, {}
        platform.state = _.extend platform.state, field.platform
        @addPlatform platform, x, y
      if field.resource.id?
        #console.log 'resource'
        resource = S.ObjectFactory.build field.resource.type, @eventBus, {}
        resource.state = _.extend resource.state, field.resource
        @addResource resource, x, y
      (
        newChannel = S.ObjectFactory.build channel.type, @eventBus, {}
        newChannel.state = _.extend newChannel.state, channel
        @addChannel newChannel, x, y, direction
      ) for direction, channel of field.channels
    null

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
            f @fields[y][x], x, y
    null

if module? and module.exports
  exports = module.exports = Map
else
  window.S.Map = Map
