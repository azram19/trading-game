express = require 'express'
hbs = require 'hbs'
app = module.exports = express.createServer()
_ = require( 'underscore' )._
app.io = require( 'socket.io' ).listen( app )
app.everyauth = require 'everyauth'

MemoryStore = express.session.MemoryStore
Communicator = require('./server/communicator').Communicator

app.Mongoose = require 'mongoose'

app.sessionStore = new MemoryStore()

app.everyauth.helpExpress app

#config the app
config = require('./config.coffee')(app, express)

app.communicator = new Communicator app

app.get '/board', ( req, res) ->
   res.render 'board'

app.get '/radialDemo', ( req, res) ->
   res.render 'radialDemo'

app.get '/lobby2', ( req, res) ->
   res.render 'lobby2'

app.get '/', ( req, res ) ->
    if app.requireAuth and req.loggedIn
      res.redirect 'lobby2'
    res.render 'index',
      title: 'Signals early chat tests'

app.get '/lobby', ( req, res ) =>
  if app.requireAuth and not req.loggedIn
    res.redirect '/'
  else
    app.Mongoose.model('User').find {}, (err, docs) ->
        console.log docs
        res.render 'lobby2'
            users: _.toArray docs
            numberOfUsers: docs.length

port =  process.env.PORT || process.env['PORT_WWW']  || 3000

app.listen port, ->
  console.log "Listening on " + port

app.on 'close', ->
  done()
