class Negotiator

  constructor: ( @communicator ) ->
    _.extend @, Backbone.Events
    @myPlayer = {}
    @game = {}
    @renderer = {}

    @on 'move:signal', (xy, dir) ->
      #console.debug 'move:signal', xy, dir
      @renderer.moveSignal xy[0], xy[1], dir

    @on 'full:channel', (xy) ->
      p = @ui.getPoint xy[0], xy[1]
      @ui.showTextBubble "Channel full", p.x+40, p.y+20

    @on 'owner:channel', (xy, dir, owner) ->
      #console.debug 'owner:channel', xy, dir, state.owner
      @renderer.changeOwnership xy[0], xy[1], owner

    @on 'owner:platform', (xy, state) ->
      #console.debug 'owner:platform', xy, state
      @renderer.capturePlatform xy[0], xy[1], state

    @on 'player:lost', (player) ->
      #console.debug 'lost', player

    @on 'resource:produce', (xy, amount, type) ->
      p = @ui.getPoint xy[0], xy[1]
      @ui.showTextBubble "-#{amount}",  p.x+40,  p.y+20
      #console.debug xy, amount, type

    @on 'resource:receive', (xy, amount, type) ->
      p = @ui.getPoint xy[0], xy[1]
      @ui.showTextBubble "+#{amount}", p.x+40, p.y+20
      #console.debug xy, amount, type

    @on 'build:platform', (x, y, type, owner) =>
      @buildPlatform x, y, type, owner
      @communicator.trigger 'send:build:platform', x, y, type, owner

    @on 'build:channel', (x, y, k, owner) =>
      @buildChannel x, y, k, owner
      @communicator.trigger 'send:build:channel', x, y, k, owner

    @on 'routing', (obj, routing) =>
      _.extend obj.platform.state.routing, routing
      routingValues = _.map routing, (route) ->
        ret =
          in: route.in
          out: route.out
      console.log '[Negotiator] new routing: ', routingValues
      @communicator.trigger 'send:routing', obj.xy[0], obj.xy[1], routingValues, obj.platform.state.owner

    @on 'scroll', @setScroll

    @on 'scroll', @setViewport

    @communicator.on 'new:player', ( playerObject, position, HQState ) =>
      console.log '[Negotiator] new player'
      pObject = S.ObjectFactory.build S.Types.Entities.Player
      playerObject = _.extend pObject, playerObject
      @renderer.addPlayer playerObject.id
      HQ = S.ObjectFactory.build S.Types.Entities.Platforms.HQ, @, playerObject
      HQ.state = HQState

      @game.addPlayer playerObject
      @game.addHQ HQ, position
      [x,y] = position
      @renderer.buildPlatform x, y, HQ
      @renderer.changeOwnership x, y, playerObject.id

    @communicator.on 'foreign:build:platform', (x, y, type, owner) =>
      if owner.id isnt @myPlayer.id
        @buildPlatform x, y, type, owner

    @communicator.on 'foreign:build:channel', (x, y, k, owner) =>
      if owner.id isnt @myPlayer.id
        @buildChannel x, y, k, owner

    @communicator.on 'foreign:routing', (x, y, routing, owner) =>
      if owner.id isnt @myPlayer.id
        field = @getField x, y
        _.extend field.platform.state.routing, routing

    @communicator.on 'state:sync', (players, startingPoints, state) =>
      @game.players = players
      @game.startingPonts = startingPoints
      @game.map.importGameState state
      @renderer.setupBoard @game.map
      $.when( @terrain.isReady() ).done =>
        @terrain.setupBoard @game.map

    @communicator.on 'players:all:ready', =>
      console.log '[Negotiator] all players loaded'
      @startGame()

    initiate = new $.Deferred()

    $.when(initiate.promise()).done(@setupUI).then( =>
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
      playerObject = S.ObjectFactory.build S.Types.Entities.Player
      @myPlayer = @gameInfo.players[@user.id].playerObject
      @myPlayer = _.extend playerObject, @myPlayer

      @communicator.join @gameInfo.name
      @communicator.trigger 'get:game:state', @gameInfo.name

    @communicator.on 'user', ( user ) =>
      getUser.resolve user

    @communicator.on 'user:game', (game) =>
      getGame.resolveWith @, [game]

    @communicator.on 'game:state', @setGameState(dfd)


  setGameState: (dfd) ->
    (players, startingPoints, state, minWidth, maxWidth, nonUser) =>
      console.log '[Negotiator] game state', players, startingPoints, state, minWidth, maxWidth, nonUser

      map = new S.Map @, minWidth, maxWidth, nonUser, @gameInfo.typeData.startingPoints
      map.importGameState state
      @game = new S.GameManager @, map
      for id, player of players
        pObject = S.ObjectFactory.build S.Types.Entities.Player, null, null
        myPlayer = _.extend pObject, player
        @game.players[id] = myPlayer
      for i, point of startingPoints
        [x,y] = point
        field = @getField x, y
        @game.map.fields[y][x].platform.state.owner = @game.players[(+i)]
      @game.startingPoints = startingPoints
      dfd.resolveWith @

  startGame: ->
    @game.startGame()

    requestSync = =>
      mapState = JSON.stringify @game.map.extractGameState()
      players = JSON.stringify @game.players
      startingPoints = JSON.stringify @game.startingPoints
      shaObj = new jsSHA mapState + players + startingPoints, 'ASCII'
      hash = shaObj.getHash "SHA-512", "B64"
      @communicator.trigger 'get:state:sync', @gameInfo.name, hash

    @syncID = setInterval requestSync, 11*1000

  #setScroll: ( x, y ) ->
    #@renderer.setScroll x, y

  #setViewport: ( width, height ) ->
    #@renderer.setScroll width, height

  setupUI: ->
    [minWidth, maxWidth] = @game.getDimensions()
    window.ui = @ui =  new S.UIClass @, minWidth, maxWidth
    window.t = @terrain = new S.Terrain @, 'background', minWidth, maxWidth
    @renderer = new S.Renderer @, minWidth, maxWidth, _.pluck(@game.players, 'id'), @myPlayer
    $.when(@renderer.boardLoaded.promise()).done =>
      @renderer.setupBoard @game.map

      terrain = @terrain

      terrain.draw()
      $.when( terrain.isReady() ).done =>
        terrain.setupBoard.call terrain, @game.map


  buildPlatform: ( x, y, type, owner ) ->
    platform = S.ObjectFactory.build S.Types.Entities.Platforms.Normal, @, owner, type
    @game.map.addPlatform platform, x, y
    platform.trigger 'produce'
    @renderer.buildPlatform x, y, platform
    @renderer.changeOwnership x, y, owner.id

  buildChannel: ( x, y, k, owner ) ->
    channel = S.ObjectFactory.build S.Types.Entities.Channel, @, owner
    @game.map.addChannel channel, x, y, k
    @renderer.buildChannel x, y, k, channel
    @renderer.changeOwnership x, y, owner.id
    [x2 ,y2] = @game.map.directionModificators(x, y, k)
    @terrain.generateRoad x, y, x2, y2
    @renderer.changeOwnership x2, y2, owner.id

  getMenu: ( x, y ) ->
    field = @getField x, y

    if field?
      if field.platform.actionMenu?
        field.platform.actionMenu()
      else
        console.log field
        if _.isEmpty field.channels
          null
        else if (_.keys field.channels).length > 1 and not field.platform.type?
          [['build:platform'], [[]]]
        else
          possibleChannels = @getPossibleChannels x, y
          [['build:platform', 'build:channel'], [[],possibleChannels]]

  getField: ( x, y ) ->
    @game.map.getField x, y

  getPossibleChannels: (x, y) ->
    field = @getField x, y
    possibleChannels = []
    for k in [0..5]
      [nX, nY] = @game.map.directionModificators x, y, k
      nField = @getField nX, nY

      if nField?
        existingDirections = _(field.channels).keys().map((dir) ->
          (+dir)
        )
        amountOfChannels = _.keys(nField.channels).length

        if (amountOfChannels < 2 or (nField.platfrom? and nField.platfrom.type?)) and not (k in existingDirections)
          possibleChannels.push k

    console.log "[Negotiator][possible channels]", x, y, possibleChannels

    possibleChannels

window.S.Negotiator = Negotiator
