class ComClient
  constructor: ( @socket ) ->
    @id = 7

  getSocket: =>
    @socket

  getId: =>
    @id

exports.ComClient = ComClient
