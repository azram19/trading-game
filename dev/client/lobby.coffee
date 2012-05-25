$ ->
  w = window 
  w.communicator = new Communicator()
  w.messages = messages = new Messages()
  w.lobby = lobby = new LobbyView collection: messages