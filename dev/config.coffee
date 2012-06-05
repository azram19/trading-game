module.exports = ( app, express ) ->
  config = @

  app.facebookAppId = '381600771875818'
  app.facebookAppSecret = '1cb71dd07064e3d110f0d76695961664'
  app.facebookScope = 'email'

  app.sessionSecret = 'veryFuckingSecret'
  app.sessionKey = 'express.sid'

  app.requireAuth = true
  app.usersByFbId = {}

  app.mongoURL = 'mongodb://signal:signals11@ds033097.mongolab.com:33097/heroku_app4770943'


  #abstraction of database connection
  app.connectDb = ( fn ) =>
    self = @

    #connect
    app.Mongo.Db.connect app.mongoURL, (err, db) ->

      #check if there are no errors
      app.Mongo.assert.equal null, err

      #execute the opreation
      fn.apply self, arguments


  #Everyauth - Facebook
  app.everyauth.facebook
    .appId( app.facebookAppId )
    .appSecret( app.facebookAppSecret )
    .scope( app.facebookScope )
    .findOrCreateUser( (session, accessToken, accessTokExtra, fbUserMetadata) ->
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

    app.use express.session(
      secret: app.sessionSecret
      key: app.sessionKey
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
