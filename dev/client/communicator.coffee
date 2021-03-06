class Communicator
  constructor: ( @host ) ->
    self = @
    @com = {}

    _.extend @com, Backbone.Events

    @id = null

    if @host?
      @host = 'http://localhost:8080'

    #connect to the host
    @socket = io.connect @host, @socketConfig

    #listening to basic connection events
    @socket.on 'connecting', @handleConnecting
    @socket.on 'connect', @handleConnected
    @socket.on 'connect_failed', @handleConnectFailed
    @socket.on 'disconnect', @handleDisconnected
    @socket.on 'error', @handleError
    @socket.on 'ping', @handlePing
    @socket.on 'reconnect', @handleReconnected
    @socket.on 'reconnecting', @handleReconnecting
    @socket.on 'reconnect_failed', @handleReconnectFailed

    #listening to the client game events and pass them to the server
    @com.on 'all', @parseClientEvent, @, false

  ###
  communication layer handlers for communication events
  other objects can subscribe anyway using comuunicator.on event, fn
  ###
  handleConnected: =>
    console.info "Communicator: Successfully connected to the server."

  handleConnectFailed: ( reason )  =>
    console.error 'Communicator: Unable to connect Socket.IO', reason

  handleConnecting: ( transport ) =>
    console.info "Communicator: Connecting " + transport

  handleDisconnected: =>
    console.info "Communicator: Disconnected from the server."

  handleError: ( reason ) =>
    console.error 'Communicator: Unable to connect Socket.IO', reason

  handlePing: =>
    #self = @
    @socket.emit 'pong'
    @socket.once 'lag', ( lag ) =>
      @lag = lag

  handleReconnected: ( transport, attempts ) =>
  handleReconnecting: ( delay, attempts ) =>
  handleReconnectFailed: =>

  ###
  extend functions to handle events on both communicator and server
  ###
  on: ( events, callback, context, socket ) =>
    @com.on events, callback

    if not socket? or socket
      @socket.on events, callback

  off: ( events, callback, context, socket ) =>
    @com.off events, callback

    if not socket? or socket
      @socket.removeListener events, callback

  trigger: =>
    @com.trigger.apply @com, arguments

  #parse an event
  parseClientEvent: =>
    console.log "Communicator: parse ", arguments

    if event is 'disconnect'
      @socket.disconnect()
    else
      @passClientEvent.apply @, arguments

  #send an event to the server
  passClientEvent: =>
    console.log "Communicator: pass"
    @socket.emit.apply @socket, arguments

  #join a channel on the server
  join: ( channel ) =>
    @socket.emit 'join:channel', channel, ( confirm ) =>
      if confirm
        @channel = channel

        console.log "Communicator: joined channel " + channel

        @com.trigger 'joined', channel
      else
        @com.trigger 'join_failed'
        console.error 'Communicator: server does not love you'

  #leave the channel
  leave: ( channel ) =>
    if @channel is channel
      @socket.emit 'leave:channel', channel, ( confirm ) =>
          @com.trigger 'left'
          @channel = ''

window.S.Communicator = Communicator
