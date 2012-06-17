$ ->
  if $('#main.lobby2').length > 0
    communicator = new S.Communicator()
    messages = new S.Collections.Messages([{'author':'pies','message':'asdasd'}])
    lobby = new S.Views.LobbyView
      communicator: communicator
      collection: messages
      el : $('#main.lobby2')[0]

    lobby.render()

  if $('#canvasWrapper').length > 0
    location = window.location.href
    if _.include location.split('/'), 'board'
      console.log 'we\'re on board'
    else
      communicator = new S.Communicator()
      negotiate = new S.Negotiator communicator
      chat = new S.Chat
        communicator: communicator
        collection: new S.Collections.Messages()

      window.negotiate = negotiate

  null
