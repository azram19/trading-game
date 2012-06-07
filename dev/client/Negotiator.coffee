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
      #console.debug 'build:platform', x, y, owner
      platform = ObjectFactory.build Types.Entities.Platform, @, owner, type
      @game.map.addPlatform platform, x, y
      platform.trigger 'produce'
      @renderer.buildPlatform x, y, platform
    @.on 'build:channel', (x, y, k, owner) =>
      #console.debug 'build:channel', x, y, owner
      channel = ObjectFactory.build Types.Entities.Channel, @, owner
      @game.map.addChannel channel, x, y, k
      @renderer.buildChannel x, y, k, channel
    @.on 'routing', (obj, k, incoming, outgoing) =>
      obj[k].in = incoming
      obj[k].out = outgoint
      #console.debug 'routing:1', x, y, k, incoming, outgoing

  getGameState: ( channel ) ->
    player = ObjectFactory.build Types.Entities.Player
    manager = new GameManager @, [player], [[2,2]], 8, 15
    @game = manager

  setupUI: ->
    [minWidth, maxWidth] = @game.getDimensions()
    @renderer = new S.Renderer minWidth, maxWidth, _.pluck(@game.users, 'id')
    @renderer.setupBoard @game.map
    window.ui = @ui =  new S.UIClass @, minWidth, maxWidth

  getMenu: ( x, y ) ->
    field = @getField x, y
    if field?
      if field.platform.actionMenu?
        field.platform.actionMenu()
      else
        if _.isEmpty field.channels
          null
        else if field.channels.length is 2
          ['build:platform']
        else
          ['build:platform', 'build:channel']

  getField: ( x, y ) ->
    @game.map.getField x, y

window.Negotiator = Negotiator

$ ->
  if $('#canvasWrapper').length > 0
    negotiate = new Negotiator()
    for y in [0..4]
     for x in [0..4]
      negotiate.renderer.moveSignal y, x, 2
    window.negotiate = negotiate
