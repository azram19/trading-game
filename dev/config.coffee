module.exports = ( app, express ) ->
  config = @

  facebookAppId = '381600771875818'
  facebookAppSecret = '1cb71dd07064e3d110f0d76695961664'
  facebookScope = 'email'

  sessionSecret = 'veryFuckingSecret'
  sessionKey = 'express.sid'

  app.requireAuth = false
  app.usersByFbId = {}

  #Everyauth - Facebook
  app.everyauth.facebook
    .appId( facebookAppId )
    .appSecret( facebookAppSecret )
    .scope( facebookScope )
    .findOrCreateUser( (session, accessToken, accessTokExtra, fbUserMetadata) ->

      console.log fbUserMetadata.id
      app.usersByFbId[fbUserMetadata.id] = fbUserMetadata
    )
    .redirectPath( '/lobby' )

  app.everyauth.everymodule.findUserById (userId, callback) ->
    user = app.usersByFbId[userId]
    callback null, user

  #generic config
  app.configure ->
    app.set 'views', __dirname + '/server/views'
    app.set 'view engine', 'hbs'

    app.use express.bodyParser()
    app.use express.cookieParser()

    ###
    express.session
      secret: process.env.CLIENT_SECRET or "f0501b04ed9b9e6844332fce3f878d5a"
      maxAge : new Date Date.now() + 7200000 # 2h Session lifetime
      store: new app.RedisStore {client: app.redis}
    ###

    app.use express.session(
      secret: sessionSecret
      key: sessionKey
      store: app.sessionStore
    )

    app.use app.everyauth.middleware()
    app.use express.methodOverride()
    app.use express.static(__dirname + '/webroot')

  #env specific config
  app.configure 'development', ->
    app.use express.errorHandler(
      dumpExceptions: true
      showStack: true
    )

  app.configure 'production', ->
    app.use express.errorHandler()

  return config
