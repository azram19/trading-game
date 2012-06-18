#node.js requirements
S = {}
if require?
  _ = require 'underscore'
  S.Field = require '../objects/Field'
  S.ObjectFactory = require '../config/ObjectFactory'
  S.Types = require '../config/Types'
  S.HeightMap = require './HeightMap'
  cloneextend = require 'cloneextend'
else
  _ = window._
  S.Field = window.S.Field
  S.ObjectFactory = window.S.ObjectFactory
  S.Types = window.S.Types
  S.HeightMap = window.S.HeightMap

class Map

  constructor: ( @eventBus, @minWidth, @maxWidth, @nonUser, @startingFields ) ->
    @fields = {}
    @diffRows = @maxWidth - @minWidth
    @directionModUpper = [[-1, -1], [0, -1], [1, 0], [1, 1], [0, 1], [-1, 0]]
    @directionModLower = [[0, -1], [1, -1], [1, 0], [0, 1], [-1, 1], [-1, 0]]
    #initialize an empty map
    for y in [0 ... (2*@diffRows + 1)]
        for x in [0 ... @maxWidth - Math.abs(@diffRows - y)]
            @addField {}, x, y

    #Configure the map
    @flatteningFactor = 1
    @smoothingPasses = 16
    @groundLevel = 0

    mapHeight = @np2 16*(2*@diffRows + 1)
    mapWidth = @np2 16*(@maxWidth + 1)
    @heightMapSize = Math.max mapHeight, mapWidth

    #generate fields
    initializeField = ( o, x, y ) =>
      @fields[y][x] = new S.Field(x, y)
      #console.log x + " " + y + ":field"

    @iterateFields initializeField

  determineTerrain: (x, y) ->
    hy = y
    hx = x + Math.abs( @diffRows-y )

    height = @heightMap.get_cell 8*hx, 8*hy

    if height < 40
      [S.Types.Terrain.Sand]# [S.Types.Terrain.Deepwater]
    else if height < 48
      [S.Types.Terrain.Sand]# [S.Types.Terrain.Deepwater, S.Types.Terrain.Water]
    else if height < 64
      [S.Types.Terrain.Sand] #[S.Types.Terrain.Water]
    else if height < 80
      [S.Types.Terrain.Sand] #[S.Types.Terrain.Water, S.Types.Terrain.Sand]
    else if height < 100
      [S.Types.Terrain.Grass]# [S.Types.Terrain.Sand]
    else if height < 120
      [S.Types.Terrain.Grass] #[S.Types.Terrain.Sand, S.Types.Terrain.Grass]
    else if height < 170
      [S.Types.Terrain.Grass]
    else if height < 180
      [S.Types.Terrain.Grass, S.Types.Terrain.Rocks]
    else if height < 200
      [S.Types.Terrain.Rocks]
    else
      [S.Types.Terrain.Snow]

  scaleHeightMap: () ->
    for x in [0...@heightMapSize]
      for y in [0...@heightMapSize]
        @heightMap.map[x][y] = @scaleHeight @heightMap.map[x][y]

  scaleHeight: ( h ) ->
    @flatteningFactor * ( h - @groundLevel)

  smoothenTheTerrain: ( n ) ->

    for i in [0...n]
      newHeightMap = []
      for x in [0...@heightMapSize]
        newHeightMap[x] = []

      for x in [0...@heightMapSize]
        for y in [0...@heightMapSize]
          adjSec = 0
          secTotal = 0

          #to the left
          if x-1 >= 0
            adjSec++
            secTotal += @heightMap.map[x-1][y]

            #top
            if y+1 < @heigtMapSize
              adjSec++
              secTotal += @heightMap.map[x-1][y+1]

            #bototm
            if y-1 >= 0
              adjSec++
              secTotal += @heightMap.map[x-1][y-1]

          #to the right
          if x+1 < @heightMapSize
            adjSec++
            secTotal += @heightMap.map[x+1][y]

            #top
            if y+1 < @heigtMapSize
              adjSec++
              secTotal += @heightMap.map[x+1][y+1]

            #bototm
            if y-1 >= 0
              adjSec++
              secTotal += @heightMap.map[x+1][y-1]

          #top
          if y+1 < @heigtMapSize
            adjSec++
            secTotal += @heightMap.map[x][y+1]

          #bototm
          if y-1 >= 0
            adjSec++
            secTotal += @heightMap.map[x][y-1]

          newHeightMap[x][y] = (@heightMap.map[x][y] + secTotal/adjSec)/2

      @heightMap.map = newHeightMap.slice 0 #copy the array

    null

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
      skip =  _.any @startingFields, ( o ) ->
        [x2, y2] = o
        x2 == x and y2 == y

      if skip
        return null

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
            kind = S.Types.Resources.Gold
            life = S.Types.Resources.Lifes[0]()
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

  directionGet: ( x1, y1, x2, y2 ) ->
    xn = x2 - x1
    yn = y2 - y1

    if y1 < @diffRows or (y1 is @diffRows and y2 < y1)
      mods = @directionModUpper
      dir = -1

      _.each mods, ( o, i ) ->
        [xMod, yMod] = o
        if xMod == xn and yMod == yn
          dir = i
          return {}
    else if y1 > @diffRows or (y1 is @diffRows and y2 >= y1)
      mods = @directionModLower
      dir = -1
      _.each mods, ( o, i ) ->
        [xMod, yMod] = o
        if xMod == xn and yMod == yn
          dir = i
          return {}

    dir

  addField: ( field, x, y ) ->
    @fields[y] ?= {}
    @fields[y][x] = field

  addTerrain: ( terrain, x, y ) ->
    @fields[y] ?= {}
    @fields[y][x].terrain = terrain

  addResource: ( resource, x, y ) ->
    resource.behaviour.eventBus = @eventBus
    resource.state.field = @fields[y][x]
    @fields[y][x].resource = resource

  addPlatform: ( platform, x, y ) ->
    platform.behaviour.eventBus = @eventBus
    platform.state.field = @fields[y][x]
    @fields[y][x].platform = platform
    #console.log x + " " + y + " add pl"
    (
      nDir = (+dir + 3) % 6
      platform.state.routing[dir].object = channel
      channel.state.routing[nDir].object = platform
      channel.trigger 'route'
    ) for dir, channel of @fields[y][x].channels
    platform.trigger 'route'

  #k - direction [0..5] clockwise from the top
  addChannel: ( channel, x, y, k ) ->
    channel.behaviour.eventBus = @eventBus
    @fields[y] ?= {}
    @fields[y][x].channels ?= {}
    channel.state.fields.push @fields[y][x]
    channel.state.direction = k
    @fields[y][x].channels[k] = channel
    [nX, nY] = @directionModificators x, y, k
    nK = (k + 3) % 6
    @addReverseChannel channel, nX, nY, nK
    # Bind channel to routing table
    routingAddChannel = (x, y, k) =>
      if @fields[y][x].platform.type?
        nK = (k + 3) % 6
        platform = @fields[y][x].platform
        @fields[y][x].platform.state.routing[k].object = channel
        channel.trigger 'route'
        channel.state.routing[nK].object = @fields[y][x].platform
        @fields[y][x].platform.trigger 'route'

    channelRouting = (x, y, k) =>
      if not (@fields[y][x].platform.type?)
        channels = []
        #console.log '[Map] field channels on add', @getField(x, y).channels
        _.each @getField(x, y).channels, (route, index) ->
          if (+index) isnt k
            channels.push [route, index]
        dest = channels[0]
        #console.log "[Map] built channel destination", dest
        if dest?
          dest[1] = (+dest[1])
          nK = (k + 3) % 6
          nIndex = (dest[1] + 3) % 6
          #console.log "[Map] routing indices", dest[1], nIndex
          dest[0].state.routing[nIndex].object = channel
          dest[0].trigger 'route'
          channel.state.routing[nK].object = dest[0]
          channel.trigger 'route'

    routingAddChannel x, y, k
    routingAddChannel nX, nY, nK
    channelRouting x, y, k
    channelRouting nX, nY, nK

  addReverseChannel: ( channel, x, y, k ) ->
    @fields[y] ?= {}
    @fields[y][x].channels ?= {}
    @fields[y][x].channels[k] = channel
    channel.state.fields.push @fields[y][x]

  extractGameState: ->
    gameState = {}
    gameState.heightMap = @heightMap.map

    @iterateFields (field, x, y) =>
      gameState[y] ?= {}
      channels = {}
      if _.keys(field.channels).length > 0
        _.each field.channels, (channel, direction) =>
          if not (_.isEmpty channel)
            channels[direction] = _.clone channel.state
            channels[direction] = @clearRoutingObjects _.clone(channel.state)
            channels[direction].fields = _.clone channel.state.fields
            channels[direction].fields = []
            signals = channels[direction].signals.slice()
            channels[direction].signals = []
            for signal, i in signals
              signal.source.field = {}
              signal.events = {}
              channels[direction].signals.push signal
          else
            channels[direction] = {}

      platform = {}
      if field.platform.type?
        platform = _.clone field.platform.state
        platform = @clearRoutingObjects _.clone(platform)
        platform.field = {}
        signals = platform.signals.slice()
        platform.signals = []
        for signal, i in signals
          signal.source.field = {}
          signal.events = {}
          platform.signals.push signal
      resource = {}
      if field.resource.type?
        resource = _.clone field.resource.state
        resource = @clearRoutingObjects _.clone(resource)
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
      routing = _.clone state.routing
      for route of routing
        route.object = {}
      state.routing = routing
    state

  importGameState: ( gameState ) ->
    @heightMap = new S.HeightMap @heightMapSize+1

    @heightMap.map = gameState.heightMap

    @iterateFields ( field, x, y ) =>
      newField = gameState[y][x]
      @addTerrain newField.terrain, x, y
      #console.log x, y
      if newField.platform.id?
        #console.log 'platform'
        platform = S.ObjectFactory.build newField.platform.type, @eventBus, {}
        _.extend platform.state, newField.platform
        @addPlatform platform, x, y
      if newField.resource.id?
        #console.log 'resource'
        resource = S.ObjectFactory.build newField.resource.type, @eventBus, {}
        _.extend resource.state, newField.resource
        @addResource resource, x, y
      (
        newChannel = S.ObjectFactory.build channel.type, @eventBus, {}
        _.extend newChannel.state, channel
        @addChannel newChannel, x, y, (+direction)
      ) for direction, channel of newField.channels
    null

  getChannel: (x, y, k) ->
    field = @getField x, y
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
