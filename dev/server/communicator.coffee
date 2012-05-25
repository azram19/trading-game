Session = require( 'connect' ).middleware.session.Session
ComClient = require './communicationClient'
_ = require( 'underscore' )._
Backbone = require( 'backbone' )

###
Stores information about all connected clients, and handles actual
message passing to and between clients.
###
class Communicator
  constructor: ( @app, @channel ) ->
    self = @
    _.extend @, Backbone.Events

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
        data.cookie = parseCookie data.header.cookie
        #get session id
        data.sessionID = data.cookie['express.sid']

        #get data from the store
        sessionStore.get data.sessionID, ( err, session ) ->
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
      client = new ComClient socket
      @clients[ client.getID() ] = client

      #remember to refresh the session
      intervalId = setInterval( () ->
          hs.session.reload( () ->
            hs.session.touch().save()
          )
        , 60 * 1000 )

      #client disconnects
      socket.on 'disconnect', () ->
        #clear the scoekt interval to stop refreshing
        clearInterval intervalId

  configHandlers: =>

  ping: =>
    clients = @sockets.clients()

    ping = ( client ) ->
      data = socket.handshake.session
      startTime = new Date()

      client.volatile.emit 'ping', 1, ->

        #compute the lag, save it
        stopTime = new Data()
        lag = ( stopTime - startTime ) / 2
        data.lag = lag
        data.save()

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
