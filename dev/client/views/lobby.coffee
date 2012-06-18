#View responsible for the game lobby
class LobbyView extends Backbone.View
  collection: S.Collections.Messages

  initialize: ->
    @communicator = @options.communicator

    #Get templates
    @messageTemplate = Handlebars.templates['lobbyMessage']
    @messagesTemplate = Handlebars.templates['lobbyMessages']

    #Bind to changes and update the view
    @collection.bind 'add', @addMessage
    @collection.bind 'reset', @resetMessages
    @games = new S.Collections.Messages
    @games.bind 'add', @addGame

    #Listen to the server
    @communicator.on 'message:new', @handleServerMessage
    @communicator.on 'user', @handleUser
    #Update list of games when something interesting happens
    @communicator.on 'game:lobby:new', @handleNewGame
    @communicator.on 'game:lobby:change', @handleGameChange
    @communicator.on 'game:lobby:close', @handleGameClose

    #Bootstrap data
    @communicator.on 'friends:load', @handleFriends
    @communicator.on 'chat:load', @handleChat

    KeyboardJS.bind.key 'enter', @newMessage, =>
      $( '#chat textarea:focus' ).val ''

  #Add new message to the chat
  addMessage: ( model ) =>
    msg = model.toJSON()

    msg = @messageTemplate msg
    $( '#chat ul' ).append msg
    $( "#chat .nano" ).nanoScroller scroll: 'bottom'

  # Reset chat with messages from the server
  resetMessages: () =>
    msgs = @collection.toJSON()
    console.log "[Chat] Reset", msgs

    html = @messagesTemplate messages: msgs
    $( '#chat ul' ).html html
    $( "#chat .nano" ).nanoScroller scroll: 'bottom'

  # Add new game to lobby
  addGame: ( model ) =>
    console.log "Lobby: New Game"

  handleFriends: ( friends  ) =>
    console.log "[Lobby] friends", friends

    friends.push @user
    friends = _.map friends, ( o ) ->
      if o.highscore?
        o
      else
        o.highscore = 0
        o

    friends = _.sortBy friends, ( o ) -> o.highscore

    maxScore = friends[0].highscore
    if maxScore < 1000
      maxScore = 1000

    minScore = 0
    scale = (maxScore + minScore) / 10

    now = maxScore
    groups = []
    group = 1

    for i in [0..10]
      groups.push {
        class: i
        users: []
      }

    (
      #prepare object
      f.firstname = f.name.split(' ')[0]

      if f.highscore > now - scale
        #add user to a group if it is not already full
        if groups[group].users.length < 3
          groups[group].users.push f
      else
        #fix the group index
        m = Math.floor (now - f.highscore)/scale
        now = now - m*scale
        group += m

        if group > 10
          group = 10

        console.log group

        groups[group].users.push f
    ) for f in friends

    groups = _.map groups, ( group ) ->
      if group.users.length > 3
        group.users = group.users.splice 0, 3
      group

    scoreTemplate = Handlebars.templates.highscoreTicker
    html = scoreTemplate groups: groups

    console.log maxScore, groups

    $( ".ranking" ).html html
    $( ".userScore" ).html maxScore

  handleChat: ( messages ) =>
    if messages.length? and messages.length > 0
      msgs = ((
        msg.author = msg.sender.name
        msg.sender = msg.sender._id
        msg)for msg in messages)

      @collection.reset msgs

  handleNewGame: ( data ) =>
    game = new S.Models.Game data
    @games.add game

  handleServerMessage: ( data ) =>
    msg = new S.Models.Message data
    @collection.add msg

  handleUser: ( user ) =>
    @user = user
    @communicator.trigger "fetch:friends", user
    @communicator.trigger "fetch:messages", 'lobby'

  newMessage: =>
    #Get the textarea and check if we are focused on it
    textarea = $ '#chat textarea:focus'
    if textarea.length > 0

      #set message attributes
      author = @user.name
      message = textarea.val()
      sender = @user._id

      date = new Date()
      hour = date.getHours()
      minute = date.getMinutes()

      if hour < 10
        hour = "0#{ hour }"

      if minute < 10
        minute = "0#{ minute }"

      time = "#{ hour }:#{ minute }"

      #clean textarea value
      textarea.val ''

      #create the message
      msg = new S.Models.Message
        author: author
        content: message
        sender: sender
        time: time
        channel: 'lobby'

      #add message to the collection
      @collection.add msg

      #send message to the server
      @communicator.trigger 'message:add', msg.toJSON()

  render: =>
    msgs =  @messagesTemplate messages: @collection.toJSON()

    $( '#chat ul' ).html msgs
    $( "#chat .nano" ).nanoScroller()

window.S.Views.LobbyView = LobbyView
