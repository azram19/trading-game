class Negotiator

  constructor: ->
    _.extend @, Backbone.Events
    @getGameState()
    @setupUI()

    @.on 'move:signal', (xy, dir) ->
      #console.debug 'move:signal', xy, dir
      @renderer.moveSignal xy[0], xy[1], dir

    @.on 'owner:channel', (xy, dir, state) ->
      #console.debug 'owner:channel', xy, dir, state.owner
      @renderer.captureChannel xy[0], xy[1], dir, state

    @.on 'owner:platform', (xy, state) ->
      #console.debug 'owner:platform', xy, state
      @renderer.capturePlatform xy[0], xy[1], state

    @.on 'player:lost', (player) ->
      #console.debug 'lost', player

    @.on 'resource:produce', (xy, amount, type) ->
      #console.debug xy, amount, type

    @.on 'resource:receive', (xy, amount, type) ->
      #console.debug xy, amount, type

    @.on 'build:platform', (x, y, type, owner) =>
      console.debug 'build:platform', x, y, owner
      platform = S.ObjectFactory.build S.Types.Entities.Platforms.Normal, @, owner, type
      @game.map.addPlatform platform, x, y
      platform.trigger 'produce'
      @renderer.buildPlatform x, y, platform

    @.on 'build:channel', (x, y, k, owner) =>
      channel = S.ObjectFactory.build S.Types.Entities.Channel, @, owner
      @game.map.addChannel channel, x, y, k
      @renderer.buildChannel x, y, k, channel
      @renderer.changeOwnership x, y, owner.id

    @.on 'routing', (obj, routing) =>
      _.extend obj.platform.state.routing, routing

    @.on 'scroll', @setScroll

    @.on 'scroll', @setViewport

  getGameState: ( channel ) ->
    nonuser = S.ObjectFactory.build S.Types.Entities.Player
    map = new S.Map @, 8, 15, nonuser

    player = S.ObjectFactory.build S.Types.Entities.Player
    player2 = S.ObjectFactory.build S.Types.Entities.Player

    manager = new S.GameManager @, map
    manager.users = [player, player2]
    manager.initialMapState [[2,2], [3,3]]
    @game = manager

  #setScroll: ( x, y ) ->
    #@renderer.setScroll x, y

  #setViewport: ( width, height ) ->
    #@renderer.setScroll width, height

  setupUI: ->
    [minWidth, maxWidth] = @game.getDimensions()
    window.ui = @ui =  new S.UIClass @, minWidth, maxWidth
    window.t = @terrain = new S.Terrain 'background', minWidth, maxWidth
    @renderer = new S.Renderer minWidth, maxWidth, _.pluck(@game.users, 'id')
    console.log 'renderer constructor triggered'
    $.when(@renderer.boardLoaded.promise()).done =>
      console.log 'renderer constructor finished'
      @renderer.setupBoard @game.map

    #@terrain.draw 2 - not extremely fast, disabled for debugging

  getMenu: ( x, y ) ->
    field = @getField x, y
    if field?
      if field.platform.actionMenu?
        field.platform.actionMenu()
      else
        if _.isEmpty field.channels
          null
        else if (_.keys field.channels).length > 1 and not field.platform.type?
          ['build:platform']
        else
          ['build:platform', 'build:channel']

  getField: ( x, y ) ->
    @game.map.getField x, y

window.S.Negotiator = Negotiator
