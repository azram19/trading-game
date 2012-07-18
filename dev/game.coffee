express = require 'express'
hbs = require 'hbs'
app = module.exports = express.createServer()
_ = require( 'underscore' )._
Logger = require './server/util/Logger'
app.io = require( 'socket.io' ).listen( app )
app.everyauth = require 'everyauth'

MemoryStore = express.session.MemoryStore
Communicator = require './server/communicator'
GameServer = require './server/GameServer'

Promise = require "promised-io/promise"

request = require 'request'

app.Mongoose = require 'mongoose'

Logger.defaults
  level: 5
  name: 'Main'
log = Logger.Logger()

log.error 'massive error'
log.warn 'not so massive warning'
log.info 'some info'
log.debug 'crazy debug output'
log.trace 'for really keen'

app.sessionStore = new MemoryStore()

app.everyauth.helpExpress app

#config the app
config = require('./config.coffee')(app, express)

app.gameServer = new GameServer
app.communicator = new Communicator app

app.get '/lobby2', ( req, res ) ->
  if app.requireAuth and not req.loggedIn
    res.redirect '/'
  else
    #history = app.getHistory req.user
    #highscores = app.getHighscores()

    games = JSON.parse app.gameServer.getGames()
    games = _.map games, ( o ) ->
      o.playersConnected = ( _.flatten o.players ).length
      o.playersRequried =
        o.typeData.numberOfSides *
        o.typeData.playersOnASide

      o

    res.render 'lobby2',
      games: games
      title: 'Signals - lobby'
      bodyClass: 'lobby'
      history:[
        {name: "Piotr Bar"
        result: "Won"},
        {name: "Robert Kruszewski"
        result: "Defeated"},
        {name: "Łukasz Koprowski"
        result: "Won"}
      ]
      highscores:[
        {
          position: 1
          name: "Łukasz Koprowski"
          points: 1234
        },
        {
          position: 2
          name: "Piotr Bar"
          points: 1034
        },
        {
          position:3
          name: "Robert Kruszewski"
          points: 1002
        },
        {
          name: "Piotr Bar"
          points: 1034
        },
        {
          name: "Robert Kruszewski"
          points: 1002
        },
        {
          name: "Piotr Bar"
          points: 1034
        },
        {
          name: "Robert Kruszewski"
          points: 1002
        },
        {
          name: "Piotr Bar"
          points: 1034
        },
        {
          name: "Robert Kruszewski"
          points: 1002
        },
        {
          name: "Robert Kruszewski"
          points: 1002
        }
      ]

app.get '/game/join', ( req, res ) ->
  if app.requireAuth and req.loggedIn
    #Get player and game details
    player = req.user.id
    gameName = app.gameServer.joinGame player
    res.redirect '/game/' + gameName
  else
    res.redirect '/'

app.get '/game/:gameName', ( req, res ) ->
  if app.requireAuth and req.loggedIn
    userId = req.user.id
    game =  app.gameServer.getUserGame userId
    [x, y] = app.gameServer.getUIDimensions game.name
    if game.name isnt req.params.gameName
      res.redirect '/game/' + game.name
    else
      res.render 'board',
        x: x
        y: y
  else
    res.redirect '/'

app.get '/', ( req, res ) ->
  if app.requireAuth and req.loggedIn
    res.redirect 'lobby2'
  else
    res.render 'index',
      title: 'Signals'
      bodyClass: 'entrance'

port =  process.env.PORT || process.env['PORT_WWW']  || 3000

app.listen port, ->
  console.log "Listening on " + port

app.on 'close', ->
  done()
