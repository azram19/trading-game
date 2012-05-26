Session = require( 'connect' ).middleware.session.Session
ComClient = require( './communicationClient' ).ComClient
_ = require( 'underscore' )._
Backbone = require( 'backbone' )
parseCookie = require('connect').utils.parseCookie

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
    @app.io.set 'authorization', ( data, accept) ->
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

    @sockets.on 'connection', ( socket ) ->
      hs = socket.handshake
      client = new ComClient socket
      @clients[ client.getId() ] = client

      socket.on 'message:add', ( data ) ->
        socket.broadcast.to( client.getChannel() ).emit 'message:new', data

      #client want to join a channel
      socket.on 'join:channel', ( channel, fn ) ->
        data = socket.handshake.session

        #leave a channel user is currently conencted to
        @clientLeaveChannel client
        @clientJoinChannel client, channel

        data.currentChannel = channel

        fn true

      socket.on 'leave:channel', ( channel ) ->
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

  ###
  1 =
    clientIds : [] - receivers
    sourceId: int - sender
    emit : bool
    volatile: bool
    channel: string
    room: string
    event: string
    data: {} or string - string for send
    fn: () ->
  ###
  send: ( event, desc, data ) =>
    send = ( clientId ) ->
      socket = getClientById().getSocket()

      #set volatile flag if on
      if data.volatile
        socket = socket.volatile

      #sent data
      if emit or not send?
        socket.emit data.event, data.data, data.fn
      else
        socket.send data.data

    send clientId for clientId in clientIds

  start: =>
    self = @


  getClientById: ( id ) =>
    #TODO


exports.Communicator = Communicator
