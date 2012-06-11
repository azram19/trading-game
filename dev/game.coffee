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

app.gameServer = new GameServer
app.communicator = new Communicator app

app.get '/board', ( req, res ) ->
   res.render 'board'

app.get '/terrain', ( req, res ) ->
   res.render 'terrain'

app.get '/radialDemo', ( req, res ) ->
   res.render 'radialDemo'

app.get '/lobby2', ( req, res ) ->
  if app.requireAuth and not req.loggedIn
    res.redirect '/'
  else
    games = JSON.parse app.gameServer.getGames()
    games = _.map games, ( o ) ->
       o.playersConnected = ( _.flatten o.players ).length
       o.playersRequried =
         o.typeData.numberOfSides *
         o.typeData.playersOnASide

       o
    res.render 'lobby2',
      games: games

app.get '/game/:gameName/join', ( req, res ) ->
  if app.requireAuth and req.loggedIn
    #Get player and game details
    player = req.user.id
    gameName = req.params.gameName
    app.gameServer.joinGame gameName, player
    res.redirect '/game/' + gameName
  else
    res.redirect '/'

app.get '/game/:gameName', ( req, res ) ->
  if app.requireAuth and req.loggedIn
    userId = req.user.id
    game =  app.gameServer.getUserGame userId
    if game.name isnt req.params.gameName
      res.redirect '/game/' + game.name
    else
     res.render 'board'
  else
    res.redirect '/'

app.get '/', ( req, res ) ->
    if app.requireAuth and req.loggedIn
      res.redirect 'lobby2'
    else
      res.render 'index',
        title: 'Signals'

port =  process.env.PORT || process.env['PORT_WWW']  || 3000

app.listen port, ->
  console.log "Listening on " + port

app.on 'close', ->
  done()
