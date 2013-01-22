Promise = require "promised-io/promise"
_ = require('underscore')._

module.exports = exports = ( app, express ) ->
  config = @

  RedisStore = require('connect-redis')(express)
  # have a great time impersonating this page
  # I am hijacking this app
  #app.facebookAppId = '381600771875818'
  #app.facebookAppSecret = '1cb71dd07064e3d110f0d76695961664'

  app.facebookAppId = '403369609724719'
  app.facebookAppSecret = 'fd3611515a2d737bfb74608cd485d58d'
  app.facebookScope = 'email'

  app.googleAppId = '1045311658397.apps.googleusercontent.com'
  app.googleAppSecret = 'Wy21_PuUibbG-tIgaLXTOX8E'
  app.googleScope = 'https://www.googleapis.com/auth/plus.me https://www.googleapis.com/auth/userinfo.profile'
  app.googleApiKey = 'AIzaSyBQkgPKmh1xpBs2hYQPRUo8rgcMPgZMYlc'

  app.sessionSecret = 'veryFuckingSecret'
  app.sessionKey = 'express.sid'

  app.requireAuth = true
  app.usersByFbId = {}

  app.mongoURL = 'mongodb://signal:signals11@ds033097.mongolab.com:33097/heroku_app4770943'

  app.redisURL = 'redis://redistogo:f0501b04ed9b9e6844332fce3f878d5a@lab.redistogo.com:9445/'

  #Everyauth - Facebook
  app.everyauth.facebook
    .appId( app.facebookAppId )
    .appSecret( app.facebookAppSecret )
    .scope( app.facebookScope )
    .findOrCreateUser( (session, accessToken, accessTokExtra, fbUserMetadata) ->
      userPromise = @Promise()
      userData =
        name: fbUserMetadata.name
        userName: fbUserMetadata.username
        id: fbUserMetadata.id
        type: 'facebook'

      app.fetchUserWithPromise userData, userPromise
      userPromise
    )
    .redirectPath( '/lobby2' )

  #Everyauth - Google+
  app.everyauth.google
    .appId( app.googleAppId )
    .appSecret( app.googleAppSecret )
    .scope( app.googleScope )
    .findOrCreateUser( (session, accessToken, extra, googleUser) ->
      userPromise = @Promise()
      userData =
        name: googleUser.name
        userName: googleUser.id
        id: googleUser.id
        type: 'google+'

      app.fetchUserWithPromise userData, userPromise
      userPromise
    )
    .redirectPath( '/lobby2' )

  app.everyauth.everymodule.moduleTimeout -1
  app.everyauth.everymodule.findUserById (userId, callback) ->
    app.Mongoose.model('User').findOne id: userId, (err, docs) =>
      Promise.when( app.getUserImgSrc( docs ) ).then ( imgSrc ) =>
        docs.imgsrc = imgSrc
        callback err, docs

  app.redis = require('redis-url').createClient app.redisURL
  app.sessionStore = new RedisStore client: app.redis

  #generic config
  app.configure ->
    app.set 'views', __dirname + '/views'
    app.set 'view engine', 'hbs'

    app.use express.bodyParser()
    app.use express.cookieParser()

    app.use express.session(
      secret: app.sessionSecret
      key: app.sessionKey
      store: app.sessionStore
    )

    app.use app.everyauth.middleware()
    app.use express.methodOverride()
    app.use express.static(__dirname + '/../webroot')

  #env specific config
  app.configure 'development', ->
    app.use express.errorHandler(
      dumpExceptions: true
      showStack: true
    )

  app.configure 'production', ->
    app.use express.errorHandler()

  return config
