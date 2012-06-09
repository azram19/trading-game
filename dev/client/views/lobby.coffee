#View responsible for the game lobby
class LobbyView extends Backbone.View
  collection: S.Collections.Messages

  initialize: ->
    @communicator = @options.communicator

    #Get temaplates
    @messageTemplate = Handlebars.templates['lobbyMessage']
    console.debug Handlebars.templates
    @messagesTemplate = Handlebars.templates['lobbyMessages']

    #Bind to changes and update the view
    @collection.bind 'add', @addMessage

    #Listen to the server
    @communicator.on 'message:new', @handleServerMessage
    @communicator.on 'user', @handleUser
    #Update list of games when something interesting happens
    @communicator.on 'game:new', @handleNewGame
    @communicator.on 'game:close', @handleGameClose

    KeyboardJS.bind.key 'enter', @newMessage, =>
      $( '#chat textarea:focus' ).val ''

  #Add new message to the chat
  addMessage: ( model ) =>
    console.log "Lobby: New message"

    msg = @messageTemplate message: model.toJSON(), user: @user
    $( '#chat ul' ).append msg
    $( "#chat .nano" ).nanoScroller scroll: 'bottom'

  handleNewGame: ( data ) =>
    console.log 'Lobby: New game has been created'
    game = new S.Models.Game data

  handleServerMessage: ( data ) =>
    console.log "Lobby: Server message"
    msg = new S.Models.Message data
    @collection.add msg

  handleUser: ( user ) =>
    @user = user

  newMessage: =>
    #Get the textarea and check if we are focused on it
    textarea = $ '#chat textarea:focus'
    if textarea.length > 0

      #set message attributes
      author = 'cat'
      message = textarea.val()

      #clean textarea value
      textarea.val ''

      #create the message
      msg = new S.Models.Message
        author: author
        message: message

      #add message to the collection
      @collection.add msg

      #send message to the server
      @communicator.trigger 'message:add', msg.toJSON()

  render: =>
    msgs =  @messagesTemplate messages: @collection.toJSON()

    $( '#chat ul' ).html msgs
    $( "#chat .nano" ).nanoScroller()

window.S.Views.LobbyView = LobbyView
