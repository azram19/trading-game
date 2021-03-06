express = require 'express'
util = require 'util'

app = module.exports = express()
server = require('http').createServer app
app.everyauth = require 'everyauth'

Communicator = require './communicator'
GameServer = require './GameServer'
Logger = require '../common/util/Logger'
hbs = require 'hbs'
_ = require( 'underscore' )._

Logger.defaults
  level: 5
  name: 'Main'

log = Logger.createLogger name: 'Server'

app.io = require( 'socket.io' ).listen server

# initialize game server and communication layer
app.gameServer = new GameServer
app.communicator = new Communicator app

#config the app
config = require('./config.coffee')(app, express)

# establish database connection and import all necessary models
db = require('./db.coffee')(app)

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

server.listen port, ->
  log.info "Listening on " + port

app.on 'close', ->
  done()
