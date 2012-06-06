module.exports = ( app, express ) ->
  config = @

  app.facebookAppId = '381600771875818'
  app.facebookAppSecret = '1cb71dd07064e3d110f0d76695961664'
  app.facebookScope = 'email'

  app.googleAppId = '1045311658397.apps.googleusercontent.com'
  app.googleAppSecret = 'Wy21_PuUibbG-tIgaLXTOX8E'
  app.googleScope = 'https://www.googleapis.com/auth/plus.me https://www.googleapis.com/auth/userinfo.profile'

  app.sessionSecret = 'veryFuckingSecret'
  app.sessionKey = 'express.sid'

  app.requireAuth = true
  app.usersByFbId = {}

  app.mongoURL = 'mongodb://signal:signals11@ds033097.mongolab.com:33097/heroku_app4770943'

  _ = require('underscore')._

  Schema = app.Mongoose.Schema
  ObjectId = Schema.ObjectId
  app.Mongoose.connect app.mongoURL
  app.Mongoose.connection.on 'open', ->
      console.log 'connected'

  app.userSchema = new Schema
        name: String
        userName: String
        id:
          type: String
          index:
            unique: true
        type: String
        highscore: Number

  app.Mongoose.model 'User', app.userSchema

  app.historySchema = new Schema
        players: [
            type: Schema.ObjectId
            ref: 'User'
        ]
        winners: [
            type: Schema.ObjectId
            ref: 'User'
        ]
        channel: String

  app.Mongoose.model 'History', app.historySchema

  app.chatSchema = new Schema
        sender:
            type: Schema.ObjectId
            ref: 'User'
        time: Date
        contet: String
        channel: String

  app.Mongoose.model 'Chat', app.chatSchema

  app.fetchUserWithPromise = (userData, promise) ->
    userModel = app.Mongoose.model 'User'
    userModel.findOne id: userData.id, (err, doc) ->
      if err?
        console.error 'Cannot fetch user data from DB'
        console.log err
        promise.fail err

      if doc?
        promise.fulfill doc
      else
        newUser = new userModel()
        newUser = _.extend newUser, userData
        newUser.save (err) ->
          if err?
            console.error 'Cannot add user'
            console.log err
            promise.fail err
          else
            promise.fulfill doc

  #Everyauth - Facebook
  app.everyauth.facebook
    .appId( app.facebookAppId )
    .appSecret( app.facebookAppSecret )
    .scope( app.facebookScope )
    .findOrCreateUser( (session, accessToken, accessTokExtra, fbUserMetadata) ->
      userPromise = this.Promise()
      userData =
        name: fbUserMetadata.name
        userName: fbUserMetadata.username
        id: fbUserMetadata.id
        type: 'facebook'
      app.fetchUserWithPromise userData, userPromise
      userPromise
    )
    .redirectPath( '/lobby2' )

  app.everyauth.google
    .appId( app.googleAppId )
    .appSecret( app.googleAppSecret )
    .scope( app.googleScope )
    .findOrCreateUser( (session, accessToken, extra, googleUser) ->
      userPromise = this.Promise()
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
    app.Mongoose.model('User').findOne id: userId, callback

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
