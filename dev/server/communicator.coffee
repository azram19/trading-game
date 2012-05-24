class Communicator
  constructor: ( @app, @channel ) ->
    self = @
    _.extend @, Backbone.Events

    @ready = false
    @queue = []

    @app = app
    @state = 'server'
    @connected = 0
    @connectionTimeOut = 1000 # 1sec
    @sockets = @app.io.of channel

    #wait for everyone to connect
    @sockets.on 'connection', ( socket ) ->
      socket.on 'disconnect'


  start: =>
    self = @



  getClientById: ( id ) =>
    #TODO

#Client/Server unification
if exports?
  if module? and module.exports
    exports = module.exports = Communicator
  exports.Communicator = Communicator
else
  window['Communicator'] = Communicator
