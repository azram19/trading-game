express = require 'express'
hbs = require 'hbs'
app = module.exports = express.createServer()
_ = require( 'underscore' )._
app.io = require( 'socket.io' ).listen( app )
app.everyauth = require 'everyauth'

MemoryStore = express.session.MemoryStore
Communicator = require('./server/communicator').Communicator

app.sessionStore = new MemoryStore()
app.RedisStore = require('connect-redis')(express)

app.everyauth.helpExpress app

# Heroku redistogo connection
#if process.env.REDISTOGO_URL
  #rtg   = require('url').parse process.env.REDISTOGO_URL
  #app.redis = require('redis').createClient rtg.port, rtg.hostname
  #app.redis.auth rtg.auth.split(':')[1] # auth 1st part is username and 2nd is password separated by ":"
## Localhost
#else
  #app.redis = require("redis").createClient()

#config the app
config = require('./config.coffee')(app, express)

app.communicator = new Communicator app

app.get '/board', ( req, res) ->
   res.render 'board' 

app.get '/', ( req, res ) ->
    if app.requireAuth and req.loggedIn
      res.redirect 'lobby'
    res.render 'index',
      title: 'Signals early chat tests'

app.get '/lobby', ( req, res ) ->
  if app.requireAuth and not req.loggedIn
    res.redirect '/'
  else
    usersArray = _.toArray app.usersByFbId
    res.render 'lobby'
      users: usersArray
      numberOfUsers: usersArray.length

port =  process.env.PORT || 3000 ##|| process.env['PORT_WWW']  || 8080

app.listen port, ->
  console.log "Listening on " + port

app.on 'close', ->
  done()
