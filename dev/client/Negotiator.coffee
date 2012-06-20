class Negotiator

  constructor: ( @communicator ) ->
    self= @
    @started = false
    _.extend @, Backbone.Events
    @myPlayer = {}
    @game = {}
    @renderer = {}

    window.loader = @loader = new S.Loader()
    @timer = new S.Timer @
    @timer.setTime 900

    $.when( @loader.start() ).then ->

    @loading = new $.Deferred()

    @on 'move:signal', (xy, dir) ->
      #console.debug 'move:signal', xy, dir
      @renderer.moveSignal xy[0], xy[1], dir

    @on 'full:channel', (fields) ->
      p1 = @ui.getPoint fields[0].xy[0], fields[0].xy[1]
      p2 = @ui.getPoint fields[1].xy[0], fields[1].xy[1]
      x1 = (p2.x+p1.x)/2
      y1 = ((p2.y+p1.y)/2) + 10
      #console.log "[NEGOTIATOR]: FULL FULL CHANNEL": x1, y1
      if @renderer.boardDR.contains @renderer.boardDR.roads, fields[0] or @renderer.boardDR.contains @renderer.boardDR.roads, fields[1]
        @ui.showTextBubble "Channel full", x1, y1, color: [159, 17, 27, 1]

    @on 'owner:channel', (dest, src, ownerid, status) ->
        field = (_.intersection dest, src)[0]
        field2 = (_.difference dest, src)[0]
        @renderer.captureOwnership field.xy[0], field.xy[1], ownerid, 1
        if not (field2.platform.type?)
          console.log "field2", field2
          @renderer.captureOwnership field2.xy[0], field2.xy[1], ownerid, 2

    @on 'owner:platform', (xy, ownerid) ->
      #console.debug 'owner:platform', xy, state
      @renderer.captureOwnership xy[0], xy[1], ownerid, 1

    @on 'player:lost', (player) ->
      @communicator.trigger 'end:game', player

    @on 'time:out', () ->
      own1 = 0
      own2 = 0
      @game.map.iterateFields (field, i, j) =>
              if (@renderer.boardDR.owner[i]?[j]? and not @renderer.boardDR.contains @renderer.boardDR.ownership, [i,j])
                own2++
              else if @renderer.boardDR.contains @renderer.boardDR.ownership, [i,j]
                own1++
      console.log "chuj", own1, own2
      if own1 < own2
        @communicator.trigger 'end:game', @myPlayer, "lose"
      else if own1 is own2
        @communicator.trigger 'end:game', @myPlayer, "tie"
      else
        player = _filter @game.players, (a) -> a.id isnt @myPlayer.id
        @communicator.trigger 'end:game', player, "win"

    @on 'resource:produce', (xy, amount, type) ->
      p = @ui.getPoint xy[0], xy[1]
      if @renderer.boardDR.contains @renderer.boardDR.roads, xy
        @ui.showTextBubble "-#{amount}",  p.x+40,  p.y+20

    @on 'resource:receive', (xy, amount, type) ->
      p = @ui.getPoint xy[0], xy[1]

      name = S.Types.Resources.Names[type-6]
      if @renderer.boardDR.contains @renderer.boardDR.roads, xy
        @ui.showTextBubble "+#{amount} #{name}", p.x+40, p.y+20
      @ui.showResources amount, type


    @on 'build:platform', (x, y, type, owner) =>
      p = @ui.getPoint x, y

      cost = S.Types.Events.Build.Platform.cost
      userHas = @myPlayer.resources

      canAfford = _.all cost, ( v, k ) ->
        userHas[k] >= v

      if canAfford
        i = 0
        _.each cost, ( v, k ) =>
          @myPlayer.spendResources k, v
          if @renderer.boardDR.contains @renderer.boardDR.roads, [x,y]
            @ui.showTextBubble "-#{v} #{ k }", p.x+40, p.y+20+i*20
          i++

        @buildPlatform x, y, type, @myPlayer
        @communicator.trigger 'send:build:platform', x, y, type, @myPlayer

        @ui.showResources 0, 6
        @ui.showResources 0, 7
      else if @renderer.boardDR.contains @renderer.boardDR.roads, [x,y]
        @ui.showTextBubble "Not enough resources", p.x+40, p.y+20, color: [159, 17, 27, 1]

    @on 'build:channel', (x, y, k, owner) =>
      p = @ui.getPoint x, y

      cost = S.Types.Events.Build.Channel.cost
      userHas = @myPlayer.resources

      canAfford = _.all cost, ( v, k ) ->
        userHas[k] >= v

      if canAfford
        i = 0
        _.each cost, ( v, k ) =>
          @myPlayer.spendResources k, v
          if @renderer.boardDR.contains @renderer.boardDR.roads, [x,y]
            @ui.showTextBubble "-#{v} #{ k }", p.x+40, p.y+20+i*20
          i++

        @buildChannel x, y, k, @myPlayer
        @communicator.trigger 'send:build:channel', x, y, k, @myPlayer

        @ui.showResources 0, 6
        @ui.showResources 0, 7
      else if @renderer.boardDR.contains @renderer.boardDR.roads, [x,y]
        @ui.showTextBubble "Not enough resources", p.x+40, p.y+20, color: [159, 17, 27, 1]

    @on 'routing', (obj, routing) =>
      _.extend obj.platform.state.routing, routing
      obj.platform.trigger 'route'
      _.each routing, ( route ) ->
        if route.type?
         route.object.trigger 'route'

      routingValues = {}

      for dir, route of routing
        ret =
          in: route.in
          out: route.out
        routingValues[dir] = ret

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
      HQ.state.owner = playerObject
      @game.addPlayer playerObject, position
      @game.addHQ HQ, position
      [x,y] = position
      @renderer.buildPlatform x, y, HQ
      @renderer.changeOwnership x, y, playerObject.id
      @renderer.loading.notify 250

    @communicator.on 'foreign:build:platform', (x, y, type, owner) =>
      if owner.id isnt @myPlayer.id
        @buildPlatform x, y, type, owner

    @communicator.on 'foreign:build:channel', (x, y, k, owner) =>
      if owner.id isnt @myPlayer.id
        @buildChannel x, y, k, owner

    @communicator.on 'foreign:routing', (x, y, routing, owner) =>
      if owner.id isnt @myPlayer.id
        field = @getField x, y
        routes = field.platform.state.routing
        for dir, route of routing
          routes[dir].in = route.in
          routes[dir].out = route.out

    @communicator.on 'state:sync', (players, startingPoints, state) =>
      @game.map.importGameState state
      for id, player of players
        pObject = S.ObjectFactory.build S.Types.Entities.Player, null, null
        myPlayer = _.extend pObject, player
        @game.players[id] = myPlayer
      for i, point of startingPoints
        [x,y] = point
        field = @getField x, y
        @game.map.fields[y][x].platform.state.owner = @game.players[(+i)]
      @game.startingPoints = startingPoints
      @renderer.setupBoard @game.map

    @communicator.on 'game:over', (player, status) =>
      console.log 'GameOver', player
      if status is "tie"
        @ui.gameTied()
      else if player.id is @myPlayer.id
        @ui.gameOver()
      else
        @ui.gameWon()

    @communicator.on 'time:sync', ( time ) =>
      lag = 0
      if @communicator.lag?
        lag = (+@communicator.lag)/1000
      @timer.setTime time - Math.round(2 * lag)

    @communicator.on 'players:all:ready', =>
      console.log '[Negotiator] all players loaded'
      @started = true
      @startGame()
      self.timer.start()

    initiate = new $.Deferred()
    uiLoaded = new $.Deferred()

    $.when(initiate.promise()).done( @setupUI uiLoaded )

    $.when(uiLoaded.promise()).done( =>
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
      lag = 0
      if @communicator.lag?
        lag = (+@communicator.lag)/1000
      console.log '[Negotitator] timer time ', game.time - Math.round(2 * lag)
      @timer.setTime game.time - Math.round(2 * lag)
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
        if myPlayer.id isnt @myPlayer.id
          @game.players[id] = myPlayer
        else
          @game.players[id] = @myPlayer
      console.log @game.players
      for i, point of startingPoints
        [x,y] = point
        field = @getField x, y
        @game.map.fields[y][x].platform.state.owner = @game.players[i]
      @game.startingPoints = startingPoints
      dfd.resolveWith @

  startGame: ->
    @game.startGame()
    sync = =>
      @communicator.trigger 'sync:time', @user.id

    setInterval sync, 5000

    requestSync = =>
      mapState = JSON.stringify @game.map.extractGameState()
      console.log '[Negotiator] successfully converted map state'
      players = JSON.stringify @game.players
      startingPoints = JSON.stringify @game.startingPoints
      shaObj = new jsSHA mapState + players + startingPoints, 'ASCII'
      hash = shaObj.getHash "SHA-512", "B64"
      @communicator.trigger 'get:state:sync', @gameInfo.name, hash

    #@syncID = setInterval requestSync, 11*1000

  #setScroll: ( x, y ) ->
    #@renderer.setScroll x, y

  #setViewport: ( width, height ) ->
    #@renderer.setScroll width, height

  setupUI: (dfd) ->
    =>
      [minWidth, maxWidth] = @game.getDimensions()
      @ui =  new S.UIClass @, minWidth, maxWidth
      @terrain = new S.Terrain @, 'background', minWidth, maxWidth
      @renderer = new S.Renderer @, minWidth, maxWidth, _.pluck(@game.players, 'id'), @myPlayer

      @loader.register @terrain.loading.promise(), 400
      @loader.register @renderer.loading.promise(), 100
      @loader.register @loading.promise(), 100

      $.when(@renderer.boardLoaded.promise()).done =>
        @renderer.loading.notify 50

        @renderer.setupBoard @game.map

        @renderer.loading.notify 50

        @terrain.draw()

        @renderer.loading.notify 250
        if _.keys(@game.players).length is 2
          @renderer.loading.notify 250

        @ui.start()
        dfd.resolveWith @



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
    nK = (k + 3) % 6
    @renderer.buildChannel x2, y2, nK, channel
    ownerIDs = []
    field = @getField(x2,y2)
    for k in [0..5]
      channel = field.channels[k]
      if channel?
        ownerIDs = _.union ownerIDs, [channel.state.owner.id]
    if _.keys(field.channels).length >= 2 and ownerIDs.length is 1
      @renderer.changeOwnership x2, y2, owner.id

  nonUserId: ( user ) ->
    @game.map.nonUser.id

  directionGet: (user, x1, y1, x2, y2) ->
    @game.map.directionGet x1, y1, x2, y2

  getMenu: ( x, y ) ->
    field = @getField x, y

    if field?
      if field.platform.actionMenu?
        field.platform.actionMenu()
      else
        #console.log field
        if _.isEmpty field.channels
          null
        else if (_.keys field.channels).length > 1 and not field.platform.type?
          [['build:platform'], [[]]]
        else
          possibleChannels = @getPossibleChannels x, y
          [['build:channel', 'build:platform'], [possibleChannels,[]]]

  getField: ( x, y ) ->
    @game.map.getField x, y

  getPossibleChannels: (x, y) ->
    field = @getField x, y
    possibleChannels = []
    for k in [0..5]
      [nX, nY] = @game.map.directionModificators x, y, k
      nField = @getField nX, nY

      if nField?
        amountOfChannels = _.keys(nField.channels).length

        if not field.channels[k]? and (amountOfChannels < 2 or nField.platform.type?)
          possibleChannels.push k

    console.log "[Negotiator][possible channels]", x, y, possibleChannels

    possibleChannels

window.S.Negotiator = Negotiator
