class ComClient
  constructor: ( @socket ) ->
    @id = null

  getSocket: =>
    @socket

exports.ComClient = ComClient
