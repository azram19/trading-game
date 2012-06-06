$ ->
  console.log "lobby"
  w = window
  w.communicator = communicator = new Communicator()
  w.messages = messages = new Messages([{'author':'pies','message':'asdasd'}])
  w.lobby = lobby = new LobbyView
    communicator: communicator
    collection: messages
    el : $('#main.lobby2')[0]

  lobby.render()

  w.newMessage = new Message
    author: 'kot'
    message: 'asdasd'

  null
