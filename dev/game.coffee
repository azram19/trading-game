express = require 'express'
app = express.createServer express.logger()

app.get '/', (request, response) ->
  response.send "Hello Signals, let's play!"

port = process.env.PORT || 3000

app.listen port, ->
  console.log "Listening on " + port
