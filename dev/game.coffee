express = require 'express'
hbs = require 'hbs'
app = module.exports = express.createServer()
_ = require( 'underscore' )._
app.io = require( 'socket.io' ).listen( app )
app.everyauth = require 'everyauth'

MemoryStore = express.session.MemoryStore
Communicator = require './server/communicator'
GameServer = require './server/GameServer'

app.Mongoose = require 'mongoose'

app.sessionStore = new MemoryStore()

app.everyauth.helpExpress app

#config the app
config = require('./config.coffee')(app, express)

app.communicator = new Communicator app
app.gameServer = new GameServer app.communicator

app.get '/board', ( req, res) ->
   res.render 'board'

app.get '/terrain', ( req, res) ->
   res.render 'terrain'

app.get '/radialDemo', ( req, res) ->
   res.render 'radialDemo'

app.get '/lobby2', ( req, res) ->
  games = JSON.parse app.gameServer.getGames()
  games = _.map games, ( o ) ->
    o.playersConnected = ( _.flatten o.players ).length
    o.playersRequried =
      o.typeData.numberOfSides *
      o.typeData.playersOnASide

    o

  req.session.games = games

  res.render 'lobby2'
    games: games

app.get '/game/:gameName/join', ( req, res) ->

  #Get player and game details
  player = req.session.player
  gameName = req.params.gameName

  #Mock object
  player = {}
  player.name = 'john'

  app.gameServer.joinGame gameName, player.name

  res.redirect '/game/' + gameName

app.get '/game/:gameName', ( req, res ) ->
   res.render 'board'

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
        games = JSON.parse app.gameServer.getGames()
        games = _.map games, ( o ) ->
          o.playersConnected = ( _.flatten o.players ).length
          o.playersRequried =
            o.typeData.numberOfSides *
            o.typeData.playersOnASide

        req.session.games = games

        res.render 'lobby2'
            users: _.toArray docs
            numberOfUsers: docs.length
            games: games

port =  process.env.PORT || process.env['PORT_WWW']  || 3000

app.listen port, ->
  console.log "Listening on " + port

app.on 'close', ->
  done()
