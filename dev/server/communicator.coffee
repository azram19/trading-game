Session = require( 'connect' ).middleware.session.Session
ComClient = require './communicationClient'
_ = require( 'underscore' )._
Backbone = require( 'backbone' )
Promise = require "promised-io/promise"
parseCookie = require('connect').utils.parseCookie
util = require 'util'
crypto = require 'crypto'

###
Stores information about all connected clients, and handles actual
message passing to and between clients.
###
class Communicator
  constructor: ( @app, @channel ) ->
    self = @
    @com = {}

    _.extend @com, Backbone.Events

    @connected = 0
    @clients = {}
    @connectionTimeOut = 1000 # 1sec

    @sockets = if @channel? then @app.io.of channel else @app.io.sockets

    ###
    Configure authorization and shared session between Express and
    Socket.io
    ###
    @app.io.set 'log level', 1

    @app.io.set 'authorization', ( data, accept ) ->
      #checks if there is a cookie
      if data.headers.cookie

        #if there is parse it
        data.cookie = parseCookie data.headers.cookie
        #get session id
        data.sessionID = data.cookie['express.sid']

        #get data from the store
        app.sessionStore.get data.sessionID, ( err, session ) ->
          if err or not session
            #we cannot grab the session so turn the connection down
            accept 'Error', false
          else
            #accept the incoming connection and save the data
            data.session = new Session data, session
            accept null, true
      else
        #if there isn't turn down the connection
        accept 'No cookie transmitted', false

    app.gameServer.on 'update:lobby:game', (game) =>
      #console.dir 'new games arrived'
      @app.io.sockets.in('lobby').emit 'game:change', game

    app.gameServer.on 'new:lobby:game', (game) =>
      #console.dir 'new games arrived'
      @app.io.sockets.in('lobby').emit 'game:new', game

    app.gameServer.on 'all:ready', ( game ) =>
      @app.io.sockets.in(game).emit 'players:all:ready'

    app.gameServer.on 'player:ready', ( game, userId ) =>
      @app.io.sockets.in(game).emit 'player:ready', userId

    app.gameServer.on 'player:joined', ( game, player, position, HQ ) =>
      console.log '[Communicator] new player on ', game
      @app.io.sockets.in(game).emit 'new:player', player, position, HQ

    app.gameServer.on 'platform:built', ( game, x, y, type, owner ) =>
      @app.io.sockets.in(game).emit 'foreign:build:platform', x, y, type, owner

    app.gameServer.on 'channel:built', ( game, x, y, k, owner ) =>
      @app.io.sockets.in(game).emit 'foreign:build:channel', x, y, k, owner

    app.gameServer.on 'routing:changed', ( game, x, y, routing, owner ) =>
      console.log game
      @app.io.sockets.in(game).emit 'foreign:routing', x, y, routing, owner

    @sockets.on 'connection', ( socket ) =>
      hs = socket.handshake
      client = new ComClient socket
      @clients[client.getId()] = client
      client.joinChannel 'lobby'
      accessToken = ''

      if hs.session.auth?
        if hs.session.auth.facebook?
          accessToken = hs.session.auth.facebook.accessToken
        else
          accessToken = hs.session.auth.google.accessToken
        app.Mongoose.model('User').findOne id: hs.session.auth.userId, (err, docs) =>
          Promise.when( app.getUserImgSrc( docs ) ).then ( imgSrc ) =>
            docs.imgsrc = imgSrc
            socket.emit 'user', docs

      socket.on 'fetch:friends', ( user ) =>
        Promise
          .when( app.fetchFriends( user, accessToken ) )
          .then ( friends ) ->
            socket.emit 'friends:load', friends

      socket.on 'fetch:messages', ( channel ) =>
        Promise
          .when( app.fetchChat( channel ) )
          .then ( messages ) ->
            socket.emit 'chat:load', messages

      socket.on 'message:add', ( data ) =>
        @app.saveChatMessage data
        socket.broadcast.to( client.getChannel() ).emit 'message:new', data

      socket.on 'get:user:game', ( userId ) =>
        game = @app.gameServer.getUserGame userId
        socket.emit 'user:game', game

      socket.on 'get:game:state', ( name ) =>
        game = @app.gameServer.getGameInstance name
        state = game.map.extractGameState()
        socket.emit 'game:state', game.players, game.startingPoints, state, game.map.minWidth, game.map.maxWidth, game.map.nonUser

      socket.on 'set:user:ready', ( userId ) =>
        @app.gameServer.setUserReady userId

      socket.on 'send:build:platform', ( x, y, type, owner ) =>
        game = @app.gameServer.getUserGame owner.userId
        @app.gameServer.buildPlatform game.name, x, y, type, owner

      socket.on 'send:build:channel', ( x, y, k, owner ) =>
        game = @app.gameServer.getUserGame owner.userId
        @app.gameServer.buildChannel game.name, x, y, k, owner

      socket.on 'send:routing', ( x, y, routing, owner ) =>
        game = @app.gameServer.getUserGame owner.userId
        @app.gameServer.setRouting game.name, x, y, routing, owner

      socket.on 'get:state:sync', ( name, hash ) =>
        game = @app.gameServer.getGameInstance name
        hashOwn = crypto.createHash 'sha512'
        state = game.map.extractGameState()
        hashOwn.update JSON.stringify(state), 'ascii'
        players = game.players
        hashOwn.update JSON.stringify(players), 'ascii'
        startingPoints = game.startingPoints
        hashOwn.update JSON.stringify(startingPoints), 'ascii'
        hashOwn = hashOwn.digest 'base64'
        console.log '[Communicator]', hashOwn
        if hash isnt hashOwn
          socket.emit 'state:sync', game.players, game.startingPoints, state

      #client want to join a channel
      socket.on 'join:channel', ( channel, fn ) =>
        data = socket.handshake.session

        #leave a channel user is currently conencted to
        @clientLeaveChannel client
        @clientJoinChannel client, channel

        data.currentChannel = channel
        if fn?
          fn true

      socket.on 'leave:channel', ( channel ) =>
        data = socket.handshake.session

        @clientLeaveChannel client
        socket.leave channel

        data.currentChannel = null

    setInterval @ping, 1000

  clientLeaveChannel: ( client ) ->
      channel = client.getChannel()

      if channel?
        client.getSocket().leave channel
        client.leaveChannel()

  clientJoinChannel: ( client, channel ) ->
      client.joinChannel channel
      client.getSocket().join channel

  configHandlers: =>

  ping: =>
    clients = @sockets.clients()

    ping = ( client ) ->
      startTime = new Date()

      client.emit 'ping'
      client.once 'pong', ->

        #compute the lag
        stopTime = new Date()
        lag = ( stopTime - startTime ) / 2

        #inform client about the lag
        client.emit 'lag', lag

    ping client for client in clients

  start: =>
    self = @

module.exports = exports = Communicator
