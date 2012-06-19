Promise = require "promised-io/promise"
request = require 'request'

module.exports = ( app, express ) ->
  config = @

  app.facebookAppId = '381600771875818'
  app.facebookAppSecret = '1cb71dd07064e3d110f0d76695961664'
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

  _ = require('underscore')._

  Schema = app.Mongoose.Schema
  ObjectId = Schema.ObjectId
  app.Mongoose.connect app.mongoURL
  app.Mongoose.connection.on 'open', ->
    console.log '[Mongoose] connected to MongoLab'

  app.userSchema = new Schema
    name: String
    userName: String
    id:
      type: String
      index:
        unique: true
    type: String
    highscore: Number
    imgsrc: String

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
    time: String
    content: String
    channel: String

  app.Mongoose.model 'Chat', app.chatSchema

  app.getUserImgSrc = ( user ) ->
    defer = new Promise.Deferred()

    if user.type?
      if user.type is 'facebook'
        defer.resolve "https://graph.facebook.com/#{ user.id }/picture"
      else
        url = "https://www.googleapis.com/plus/v1/people/#{ user.id }?fields=image(url)&key=#{ app.googleApiKey }"
        extractImgSrc = ( error, response, dataObj ) ->
          obj = JSON.parse( dataObj ).image
          if obj? and obj.url?
            src = obj.url
          else
            src = ''
          defer.resolve src

        request.get( url, extractImgSrc )
    else
      defer.resolve ''

    defer.promise

  app.fetchFriends = ( user, accessToken ) ->
    defer = new Promise.Deferred()

    handleFacebookFriends = ( error, response, friends ) ->
      friends = JSON.parse friends
      if error or response.statusCode != 200
        console.error "[Mongoose][Fb] Cannot query graph for friends"
        console.log error
        defer.reject error
      else
        friendsIds = ( friend.id  for friend in friends.data )
        userModel = app.Mongoose.model 'User'

        handleFriends = ( err, friends ) ->
          if err?
            console.error "[Mongoose] Cannot fetch friends"
            console.log err
            defer.reject err
          else if friends.length > 0
            friendsPromises = ( app.getUserImgSrc( friend ) ) for friend in friends
            friendsGroup = Promise.all friendsPromises
            friendsGroup.then ( arrayOfImgSrcs ) ->
              (
                friends[i].imgsrc = img
              ) for img, i in arrayOfImgSrcs

              defer.resolve friends
          else
              defer.resolve []

        userModel
          .where( 'id' )
          .in( friendsIds )
          .desc( 'highscore' )
          .run handleFriends

    handleGooglePlusFriends = ( friends ) ->

    if user.type is 'facebook'
      request.get "https://graph.facebook.com/#{ user.id }/friends?access_token=#{ accessToken }",
        handleFacebookFriends
    else
      defer.resolve []

    defer.promise

  app.fetchChat = ( channel ) ->
    defer = new Promise.Deferred()
    chatModel = app.Mongoose.model 'Chat'

    handleData = ( err, docs ) =>
      if err?
        console.error 'Cannot fetch chat data from DB'
        console.log err
        defer.reject err

      if docs?
        defer.resolve docs

    chatModel
      .find( channel: channel, handleData )
      .sort( id: -1 )
      .limit( 10 )
      .populate( 'sender' )

    defer.promise

  app.saveChatMessage = ( message ) ->
    defer = new Promise.Deferred()
    chatModel = app.Mongoose.model 'Chat'

    msg = new chatModel()
    _.extend msg, message

    msg.save ( err ) ->
      if err?
        console.log '[Mongoose] Cannot save message to DB'
        console.log err
        defer.reject err
      else
        defer.resolve msg

    defer.promise

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
            promise.fulfill userData

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
    app.Mongoose.model('User').findOne id: userId, (err, docs) =>
      Promise.when( app.getUserImgSrc( docs ) ).then ( imgSrc ) =>
        docs.imgsrc = imgSrc
        callback err, docs

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
