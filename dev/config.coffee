module.exports = ( app, express ) ->
  config = @

  app.requireAuth = true;

  #Everyauth - Facebook
  app.everyauth.facebook
    .appId( '381600771875818' )
    .appSecret( '1cb71dd07064e3d110f0d76695961664' )
    .findOrCreateUser( (session, accessToken, accessTokExtra, fbUserMetadata) ->
        usersByFbId[fbUserMetadata.id] || ( usersByFbId[fbUserMetadata.id] = addUser( 'facebook', fbUserMetadata ) );
    )
    .redirectPath( '/' );

  #generic config
  app.configure ->
    app.set 'views', __dirname + '/views'
    app.set 'view engine', 'hbs'

    app.use express.bodyParser()
    app.use express.cookieParser()

    ###
    express.session
      secret: process.env.CLIENT_SECRET or "f0501b04ed9b9e6844332fce3f878d5a"
      maxAge : new Date Date.now() + 7200000 # 2h Session lifetime
      store: new app.RedisStore {client: app.redis}
    ###
    app.use express.session( secret: "kot" )

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
