$ ->
  if $('#main.lobby2').length > 0
    console.log 'fdsafdsaf'
    w = window
    w.communicator = communicator = new S.Communicator()
    w.messages = messages = new S.Collections.Messages([{'author':'pies','message':'asdasd'}])
    w.lobby = lobby = new S.Views.LobbyView
      communicator: communicator
      collection: messages
      el : $('#main.lobby2')[0]
 
    lobby.render()

  if $('#canvasWrapper').length > 0
    negotiate = new S.Negotiator()
    for y in [0..4]
     for x in [0..4]
      negotiate.renderer.moveSignal y, x, 2
    window.negotiate = negotiate

  null
