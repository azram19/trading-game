Logger = require './../common/util/Logger'
Promise = require 'promised-io/promise'
request = require 'request'
_ = require('underscore')._

# Hell a lot of mess
# Needs cleanup
# Scheduled to be done after game mechanics are working
# ...meaning not soon

module.exports = exports = ( app ) ->
  db = @

  app.Mongoose = require 'mongoose'

  log = Logger.createLogger name: 'Mongoose'

  Schema = app.Mongoose.Schema
  ObjectId = Schema.ObjectId
  app.Mongoose.connect app.mongoURL
  app.Mongoose.connection.on 'open', ->
    log.info 'connected to MongoLab'

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

  app.historySchema = new Schema(
    {
      players: [
        type: Schema.ObjectId
        ref: 'User'
      ]
      winners: [
          type: Schema.ObjectId
          ref: 'User'
      ]
      channel: String
    },
    {
      collection: 'history'
    }
  )

  app.Mongoose.model 'History', app.historySchema

  app.chatSchema = new Schema
    sender:
        type: Schema.ObjectId
        ref: 'User'
    time: String
    content: String
    channel: String

  app.Mongoose.model 'Chat', app.chatSchema

  app.getHistory = ( user ) ->
    defer = new Promise.Deferred()

    log.trace user

    handleHistory = ( err, history ) =>
      if err?
        log.error "Cannot fetch history"
        log.error err
        defer.reject err
      else if history.length > 0
        log.debug history
        history = _.map history, ( v, k ) ->
          userInWinners = _.any history.winners, ( v ) ->
            v.id == user.id

          if userInWinners
            v.win = true
          else
            v.win = false

        log.debug history
        defer.resolve history
      else
        defer.resolve []

    historyModel = app.Mongoose.model 'History'
    historyModel
      .where( user._id ).in( 'players' )
      .populate( 'players winners' )
      .run handleHistory

    defer.promise

  app.getHighscores = ->
    defer = new Promise.Deferred()

    handleHighscores = ( err, highscores ) =>
      if err?
        log.error "Cannot fetch highscores"
        log.error err
        defer.reject err
      else if highscores.length > 0
        defer.resolve highscores
      else
        defer.resolve []

    userModel = app.Mongoose.model 'User'
    userModel
      .find()
      .sort( '-highscore' )
      .limit( 10 )
      .select( 'name highscore' )
      .exec handleHighscores

    defer.promise

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
        log.error "[Fb] Cannot query graph for friends"
        log.error error
        defer.reject error
      else
        friendsIds = ( friend.id  for friend in friends.data )
        userModel = app.Mongoose.model 'User'

        handleFriends = ( err, friends ) ->
          if err?
            log.error "Cannot fetch friends"
            log.error err
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
          .sort( '-highscore' )
          .exec handleFriends

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
        log.error 'Cannot fetch chat data from DB'
        log.error err
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
        log.error 'Cannot save message to DB'
        log.error err
        defer.reject err
      else
        defer.resolve msg

    defer.promise

  app.fetchUserWithPromise = (userData, promise) ->
    userModel = app.Mongoose.model 'User'
    userModel.findOne id: userData.id, (err, doc) ->
      if err?
        log.error 'Cannot fetch user data from DB'
        log.error err
        promise.fail err

      if doc?
        promise.fulfill doc

      else
        newUser = new userModel()
        newUser = _.extend newUser, userData
        newUser.save (err) ->
          if err?
            log.error 'Cannot add user'
            log.error err
            promise.fail err
          else
            promise.fulfill userData

  return db
