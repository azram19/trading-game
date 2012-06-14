class Chat extends Backbone.View
  collection: S.Collections.Messages
  initialize: ->
    @communicator = @options.communicator
    @messageTemplate = Handlebars.templates['lobbyMessage']
    @messagesTemplate = Handlebars.templates['lobbyMessages']

    @collection.bind 'add', @addMessage
    @collection.bind 'reset', @resetMessages

    @communicator.on 'message:new', @handleServerMessage
    @communicator.on 'user', @handleUser

    @communicator.on 'chat:load', @handleChat

    KeyboardJS.bind.key 'enter', @newMessage, =>
      $( '#chat textarea:focus' ).val ''

    handleUser: ( user ) =>
      @user = user
      @communicator.trigger "fetch:friends", user
      @communicator.trigger "fetch:messages", 'lobby'

    #Add new message to the chat
    addMessage: ( model ) =>
      msg = model.toJSON()
      console.log "[Chat] New message", msg

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

    handleChat: ( messages ) =>
      console.log "[Lobby] chat ", messages

      if messages.length? and messages.length > 0
        msgs = ((
          msg.author = msg.sender.name
          msg.sender = msg.sender._id
          msg)for msg in messages)

        @collection.reset msgs

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

window.S.Chat = Chat
