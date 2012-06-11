class Negotiator

  constructor: ( @communicator ) ->
    _.extend @, Backbone.Events
    @myPlayer = {}
    @game = {}
    @renderer = {}

    @.on 'move:signal', (xy, dir) ->
      #console.debug 'move:signal', xy, dir
      @renderer.moveSignal xy[0], xy[1], dir

    @.on 'owner:channel', (xy, dir, owner) ->
      #console.debug 'owner:channel', xy, dir, state.owner
      @renderer.changeOwnership xy[0], xy[1], owner

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
      @renderer.changeOwnership x, y, owner.id

    @.on 'build:channel', (x, y, k, owner) =>
      channel = S.ObjectFactory.build S.Types.Entities.Channel, @, owner
      @game.map.addChannel channel, x, y, k
      @renderer.buildChannel x, y, k, channel

      @renderer.changeOwnership x, y, owner.id

    @.on 'routing', (obj, routing) =>
      _.extend obj.platform.state.routing, routing

    @.on 'scroll', @setScroll

    @.on 'scroll', @setViewport

    gameLoaded = new $.Deferred()
    initiate = new $.Deferred()

    @communicator.on 'game:state', @setGameState(gameLoaded)

    @communicator.on 'new:player', ( playerObject, position, HQState ) =>
      console.log '[Negotiator] new player'
      HQ = S.ObjectFactory.build S.Types.Entities.Platforms.HQ, @, playerObject
      HQ.state = HQState
      @game.addPlayer playerObject
      @game.addHQ HQ, position
      [x,y] = position
      @renderer.buildPlatform x, y, HQ
      @renderer.changeOwnership x, y, playerObject.id

    @communicator.on 'players:all:ready', =>
      console.log '[Negotiator] all players loaded'
      @game.startGame()

    $.when(initiate.promise()).then( =>
      console.log 'user and game info loaded'
    )

    $.when(gameLoaded.promise()).done(@setupUI).then( =>
      console.log 'UI has been loaded'
      @communicator.trigger 'set:user:ready', @user.id
    )
    @initiateConnection initiate

  initiateConnection: (dfd) ->
    getUser = new $.Deferred()
    getGame = new $.Deferred()

    getUser.done (user) =>
      console.log '[Negotitator] user: ', user
      @user = user
      @communicator.trigger 'get:user:game', @user.id

    getGame.done (game) =>
      console.log '[Negotiator] game: ', game
      @gameInfo = game
      @myPlayer = @gameInfo.players[@user.id].playerObject
      @communicator.join @gameInfo.name
      @communicator.trigger 'get:game:state', @gameInfo.name
      dfd.resolveWith @

    @communicator.on 'user', ( user ) =>
      getUser.resolve user

    @communicator.on 'user:game', (game) ->
      getGame.resolve game


  setGameState: (dfd) ->
    (players, startingPoints, state, minWidth, maxWidth, nonUser) =>
      console.log '[Negotiator] game state', players, startingPoints, state, minWidth, maxWidth, nonUser

      map = new S.Map @, minWidth, maxWidth, nonUser
      map.importGameState state
      @game = new S.GameManager @, map
      @game.players = players
      @game.startingPoints = startingPoints
      dfd.resolveWith @

  startGame: ->
  #setScroll: ( x, y ) ->
    #@renderer.setScroll x, y

  #setViewport: ( width, height ) ->
    #@renderer.setScroll width, height

  setupUI: ->
    [minWidth, maxWidth] = @game.getDimensions()
    window.ui = @ui =  new S.UIClass @, minWidth, maxWidth
    window.t = @terrain = new S.Terrain 'background', minWidth, maxWidth
    @renderer = new S.Renderer @, minWidth, maxWidth, _.pluck(@game.players, 'id'), @myPlayer
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
        console.log field.channels
        if _.isEmpty field.channels
          null
        else if (_.keys field.channels).length > 1 and not field.platform.type?
          ['build:platform']
        else
          ['build:platform', 'build:channel']

  getField: ( x, y ) ->
    @game.map.getField x, y

window.S.Negotiator = Negotiator
