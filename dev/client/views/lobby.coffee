#View responsible for the game lobby
class LobbyView extends Backbone.View
  collection: Messages

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

    KeyboardJS.bind.key 'enter', @newMessage, () ->
      console.debug @$el.find( 'textarea:focus' )
      @$el.find( 'textarea:focus' ).val ''

  #Add new message to the chat
  addMessage: ( model ) =>
    console.log "Lobby: New message"

    msg = @messageTemplate message: model.toJSON()
    @$el.find( '.chat ul' ).append msg

  handleServerMessage: ( data ) =>
    console.log "Lobby: Server message"
    msg = new Message data
    @collection.add msg

  newMessage: =>
    #Get the textarea and check if we are focused on it
    textarea = @$el.find 'textarea:focus'
    if textarea.length > 0

      #set message attributes
      author = 'cat'
      message = textarea.val()

      #clean textarea value
      textarea.val ''

      #create the message
      msg = new Message
        author: author
        message: message

      #add message to the collection
      @collection.add msg

      #send message to the server
      @communicator.trigger 'message:add', msg.toJSON()

  render: =>
    msgs =  @messagesTemplate messages: @collection.toJSON()

    @$el.find( '.chat ul' ).html msgs

window['LobbyView'] = LobbyView
