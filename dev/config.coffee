module.exports = ( app, express ) ->
  config = @

  app.facebookAppId = '381600771875818'
  app.facebookAppSecret = '1cb71dd07064e3d110f0d76695961664'
  app.facebookScope = 'email'

  app.sessionSecret = 'veryFuckingSecret'
  app.sessionKey = 'express.sid'

  app.requireAuth = false
  app.usersByFbId = {}

  app.mongoURL = 'mongodb://signal:signals11@ds033097.mongolab.com:33097/heroku_app4770943'

  Schema = app.Mongoose.Schema
  ObjectId = Schema.ObjectId
  app.Mongoose.connect app.mongoURL
  app.Mongoose.connection.on 'open', ->
      console.log 'connected'

  app.userSchema = new Schema
        name: String
        userName: String
        id: String
        highscore: Number
        friends: [
            type: Schema.ObjectId
            ref: 'User'
        ]

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

  
  #Everyauth - Facebook
  app.everyauth.facebook
    .appId( app.facebookAppId )
    .appSecret( app.facebookAppSecret )
    .scope( app.facebookScope )
    .findOrCreateUser( (session, accessToken, accessTokExtra, fbUserMetadata) ->
        userModel = app.Mongoose.model 'User'
        userModel.findOne id: fbUserMetadata.id, (err, doc) ->
            console.log doc
            if err?
                throw err
            if not doc?
                newUser = new userModel()
                newUser.name = fbUserMetadata.name
                newUser.userName = fbUserMetadata.username
                newUser.id = fbUserMetadata.id
                newUser.save (err) ->
                        if err?
                            throw err
    )
    .redirectPath( '/lobby' )

  app.everyauth.everymodule.findUserById (userId, callback) ->
      app.Mongoose.model('User').findById userId, callback

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
