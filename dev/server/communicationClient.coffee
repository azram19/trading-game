class ComClient
  constructor: ( @socket ) ->
    @id = @socket.id
    @channel = null

  getChannel: =>
    @channel

  getSocket: =>
    @socket

  getId: =>
    @id

  joinChannel: ( channel ) =>
    @channel = channel
    @socket.join channel

  leaveChannel: ( channel ) =>
    @socket.leave channel
    @channel = null

module.exports = exports = ComClient
