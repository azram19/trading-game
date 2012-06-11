#node.js requirements
S = {}
if require?
  _ = require 'underscore'
  S.Field = require '../objects/Field'
  S.ObjectFactory = require '../config/ObjectFactory'
  S.Types = require '../config/Types'
  S.HeightMap = require './HeightMap'
else
  _ = window._
  S.Field = window.S.Field
  S.ObjectFactory = window.S.ObjectFactory
  S.Types = window.S.Types
  S.HeightMap = window.S.HeightMap

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

    #Configure the map
    @flatteningFactor = 0.6
    @groundLevel = 80

    mapHeight = @np2 2*(2*@diffRows + 1)
    mapWidth = @np2 2*(@maxWidth + 1)
    @heightMapSize = Math.max mapHeight, mapWidth

    #generate fields
    initializeField = ( o, x, y ) =>
      @fields[y][x] = new S.Field(x, y)
      #console.log x + " " + y + ":field"

    @iterateFields initializeField

  determineTerrain: (x, y) ->
    hy = y
    hx = x + Math.abs( @diffRows-y )

    height = @heightMap.get_cell hx, hy

    if height < -5
      [S.Types.Terrain.Deepwater]
    else if height < -4
      [S.Types.Terrain.Deepwater, S.Types.Terrain.Water]
    else if height < 0
      [S.Types.Terrain.Water]
    else if height < 5
      [S.Types.Terrain.Water, S.Types.Terrain.Sand]
    else if height < 8
      [S.Types.Terrain.Sand]
    else if height < 12
      [S.Types.Terrain.Sand, S.Types.Terrain.Grass]
    else if height < 30
      [S.Types.Terrain.Grass]
    else if height < 40
      [S.Types.Terrain.Grass, S.Types.Terrain.Rocks]
    else
      [S.Types.Terrain.Rocks]

  scaleHeightMap: () ->
    for x in [0...@heightMapSize]
      for y in [0...@heightMapSize]
        @heightMap.map[x][y] = @scaleHeight @heightMap.map[x][y]

  scaleHeight: ( h ) ->
    @flatteningFactor * ( h - @groundLevel)

  np2: ( x ) ->
    Math.pow( 2, Math.round( Math.log( x ) / Math.log( 2 ) ) )

  initialise: ->
    #generate height map
    @heightMap = new S.HeightMap @heightMapSize + 1
    @heightMap.run()

    #Scale it to be more flat
    @scaleHeightMap()

    #generate fields
    initializeTerrain = ( o, x, y ) =>
      @fields[y][x].terrain = @determineTerrain x, y

    @iterateFields initializeTerrain

    #generate resources
    initializeResource = ( o, x, y ) =>
      chance = 0.72
      res = Math.random()

      #Types of terrain where each resource can exist
      resourcesTerrains = [
        S.Types.Terrain.Sand,
        S.Types.Terrain.Rocks,
        S.Types.Terrain.Grass
      ]

      goldTerrains = [
        S.Types.Terrain.Sand,
        S.Types.Terrain.Rocks
      ]

      foodTerrains = [
        S.Types.Terrain.Grass,
        S.Types.Terrain.Water
      ]

      if res < chance
        kind = ''
        life = 0

        if res > chance / 2
          if (_.intersection @fields[y][x].terrain, resourcesTerrains).length > 0
            kind = S.Types.Resources.Resources
            life = S.Types.Resources.Lifes[2]()
        else if res > chance / 3
          if (_.intersection @fields[y][x].terrain, goldTerrains).length > 0
            kind = S.Types.Resources.Gold
            life = S.Types.Resources.Lifes[0]()
        else
          if (_.intersection @fields[y][x].terrain, foodTerrains).length > 0
            kind = S.Types.Resources.Food
            life = S.Types.Resources.Lifes[1]()

        if kind
          resource = S.ObjectFactory.build kind, @eventBus, @nonUser
          resource.state.life = life

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

  addTerrain: ( terrain, x, y ) ->
    @fields[y] ?= {}
    @fields[y][x].terrain = terrain

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
      nDir = (+dir + 3) % 6
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
    gameState.heightMap = @heightMap.map

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
      terrain = field.terrain
      exportState =
        channels: channels
        platform: platform
        resource: resource
        terrain: terrain
      gameState[y][x] = exportState
    gameState

  clearRoutingObjects: (state) ->
    if state?
      (
       route.object = {}
      ) for route in state.routing
    state

  importGameState: ( gameState ) ->
    @heightMap = new S.HeightMap @heightMapSize+1

    @heightMap.map = gameState.heightMap

    @iterateFields ( field, x, y ) =>
      field = gameState[y][x]

      @addTerrain field.terrain, x, y
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
