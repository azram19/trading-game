class Communicator
  constructor: ( @host, @channel ) ->
    self = @
    _.extend @, Backbone.Events

    @id = null

    if @host?
      @host = 'http://localhost:8080'

    #connest to the host
    if @channel?
      @socket = io.connect @host + @channel, @socketConfig
    else
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
    @.on 'all', @parseClientEvent, @, false


  ###
  communication layer handlers for communication events
  other objects can subscribe anyway using comuunicator.on event, fn
  ###
  handleConnected: =>
    console.info "Communicator: Successfully connected to the server."

  handleConnectFailed: ( reason )  =>
    console.error 'Communicator: Unable to connect Socket.IO', reason

  handleConnecting: ( transport ) =>
    console.info "Communicator: Connecting" + transport

  handleDisconnected: =>
    console.info "Communicator: Disconnected from the server."

  handleError: ( reason ) =>
    console.error 'Communicator: Unable to connect Socket.IO', reason

  handlePing: =>
    self = @
    @socket.emit 'pong'
    @socket.once 'lag', ( lag ) ->
      self.lag = lag

  handleReconnected: ( transport, attempts ) =>
  handleReconnecting: ( delay, attempts ) =>
  handleReconnectFailed: =>

  ###
  extend functions to handle events on both communicator and server
  ###
  on: ( events, callback, context, socket ) =>
    super

    if not socket? or socket
      @socket.on events, callback

  off: ( events, callback, context, socket ) =>
    super

    if not socket? or socket
      @socket.removeListener events, callback


  #parse an event
  parseClientEvent: =>
    #may be problematic due to bug in some browsers
    event = arguments[0]
    data = arguments[1]
    fn = arguments[2]

   if event is 'disconnect'
    @socket.disconnect()
   else
    @passClientEvent event, data, fn

  #send an event to the server
  passClientEvent: ( event, data, fn ) =>
    @socket.emit event, data, fn


window['Communicator'] = Communicator
