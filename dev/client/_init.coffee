$ ->
  if $('#main.lobby2').length > 0
    w = window
    w.communicator = communicator = new S.Communicator()
    w.messages = messages = new S.Collections.Messages([{'author':'pies','message':'asdasd'}])
    w.lobby = lobby = new S.Views.LobbyView
      communicator: communicator
      collection: messages
      el : $('#main.lobby2')[0]
 
    lobby.render()

  if $('#canvasWrapper').length > 0
    location = window.location.href
    if _.include location.split('/'), 'board'
      console.log 'we\'re on board'
    else
      w = window
      w.communicator = communicator = new S.Communicator()
      negotiate = new S.Negotiator communicator
      window.negotiate = negotiate

  null
