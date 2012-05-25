#View responsible for the game lobby
class LobbyView extends Backbone.View
  el: '#main .lobby'
  collection: Messages

  intialize: () ->
    #Get temaplates
    @messageTemplate = Handlebars.templates['lobbyMessage']

    #Bind to changes and update the view
    @model.bind 'change', @addMessage 

  #Add new message to the chat
  addMessage: ( model ) =>
    console.log "Lobby: New massage"
    msg = @messageTemaplate model.toJSON()
    @$el.find( '.chat ul' ).append msg

  render: () ->

window['LobbyView'] = LobbyView
