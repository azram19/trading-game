class Negotiator

  constructor: ->
    _.extend @, Backbone.Events
    @getGameState()
    @setupUI()
  
    @.on 'move:signal', (xy, dir) ->
      console.debug 'move:signal', xy, dir
      @renderer.moveSignal xy[0], xy[1], dir
    @.on 'owner:channel', (xy, dir, state) ->
      console.debug 'owner:channel', xy, dir, state.owner
      @renderer.captureChannel xy[0], xy[1], dir, state
    @.on 'owner:platform', (xy, state) ->
      console.debug 'owner:platform', xy, state
      @renderer.capturePlatform xy[0], xy[1], state
    @.on 'player:lost', (player) ->
      console.log 'lost', player
    @.on 'resource:produce', (xy, amount, type) ->
      console.log xy, amount, type
    @.on 'resource:receive', (xy, amount, type) ->
      console.log xy, amount, type

  getGameState: ( channel ) ->
    player = ObjectFactory.build Types.Entities.Player
    manager = new GameManager @, [player], [[2,2]], 8, 15
    @game = manager

  setupUI: ->
    [minWidth, maxWidth] = @game.getDimensions()
    @renderer = new S.Renderer minWidth, maxWidth
    @renderer.setupBoard @game.map
    @ui =  new S.UIClass @, minWidth, maxWidth

  getMenu: ( x, y ) ->
    field = @getField x, y
    field.platform.actionMenu()

  getField: ( x, y ) ->
    @game.map.getField x, y

window.S.Negotiator = Negotiator

$ ->
  if $('#canvasWrapper').length > 0
    negotiate = new S.Negotiator()
    for y in [0..4]
     for x in [0..4]
      negotiate.renderer.moveSignal y, x, 2
    window.negotiate = negotiate