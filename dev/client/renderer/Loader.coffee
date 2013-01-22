class Loader
  constructor: () ->
    @weight = 0
    @finished = new $.Deferred()

    @waitingFor = []

    @loaded = 0
    @sumOfWeights = 1000

    @progress = 0

    @stepsToDo = 0

    @radius = 200
    @width = 20

    @startColour = [105,210,231]
    @endColour = [250,105,0]
    @currentColour = @startColour

    @loader = new createjs.Shape()
    @text = new createjs.Text()

  register: ( promise, weight ) ->
    self = @

    @waitingFor.push promise
    #@sumOfWeights += weight

    promise.progress ( n ) ->
      self.load.call self, n

  load: ( n ) ->
    @progress += n
    @loaded = @sumOfWeights / @progress

  draw: () ->
    angle = Math.PI * 2 / 100
    [sr,sg,sb] = @colourStep
    [r,g,b] = @currentColour

    nr = r + sr
    ng = g + sg
    nb = b + sb

    @loader.graphics
      .setStrokeStyle( @width, 'round' )
      .beginStroke( "rgb(#{ Math.round(nr) }, #{ Math.round(ng) }, #{ Math.round(nb) })" )
      .arc( @x, @y, @radius, @angle, @angle + angle)

    @text.color = "rgb(#{ Math.round(nr) }, #{ Math.round(ng) }, #{ Math.round(nb) })"

    @currentColour = [nr,ng,nb]
    @angle += angle

  waitForPlayers: () ->
    @text.text = "Waiting for players"

  start: () ->
    canvas = document.getElementById 'loader'
    @stage = new createjs.Stage canvas
    @stage.addChild @loader
    @stage.addChild @text

    @x = 300
    @y = 300
    @angle = Math.PI/2

    [r1,g1,b1] = @startColour
    [r2,g2,b2] = @endColour

    r3 = (r2-r1) / 100
    g3 = (g2-g1) / 100
    b3 = (b2-b1) / 100

    @colourStep = [r3, g3, b3]

    @text.x = @x
    @text.y = @y
    @text.text = "Loading"
    @text.textBaseline  = "middle"
    @text.textAlign = "center"
    @text.color = "rgb(#{ Math.round(r1) }, #{ Math.round(g1) }, #{ Math.round(b1) })"
    @text.font = "bold 32px 'Cabin', Helvetica,Arial,sans-serif"

    Ticker.addListener @

    @stage.update()
    @finished.promise()

  tick: () ->
    if @stepsToDo <  Math.ceil(@progress/@sumOfWeights*100)
      @draw()
      @stage.update()
      @stepsToDo++
    else if @progress >= @sumOfWeights
      Ticker.removeListener @
      $( ".loader" ).fadeOut( () -> $( @ ).remove() )
      @finished.resolve()

window.S.Loader = Loader
