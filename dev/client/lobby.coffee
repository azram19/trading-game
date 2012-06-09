$ ->
  console.log "lobby"
  w = window
  w.communicator = communicator = new S.Communicator()
  w.messages = messages = new S.Collections.Messages([{'author':'pies','message':'asdasd'}])
  w.lobby = lobby = new S.Views.LobbyView
    communicator: communicator
    collection: messages
    el : $('#main.lobby2')[0]

  lobby.render()

  w.newMessage = new S.Models.Message
    author: 'kot'
    message: 'asdasd'

  null
