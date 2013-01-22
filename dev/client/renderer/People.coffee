class People
  constructor: ( @events, options ) ->
    @distance = options.distance
    @time = options.time + 5

    canvas2 = document.getElementById 'animations'
    @stage = new createjs.Stage canvas2

    @buffer = []
    @moving = {}
    @allHumans = []

    @images = [
      '/img/traggerSprite.png'
    ]

    for i in [0...3]
      @create()

    createjs.Ticker.addListener @

  create: () ->
    h = new S.Human @events, @images[0], @stage, @distance, @time
    @buffer.push h
    @allHumans.push h

  transfer: ( h, i, j, i2, j2, k ) ->
    self = @

    #Transfer the human, and reset the situation once it's done
    $.when( h.transfer(i, j, i2, j2, k) ).done () ->
      self.clear.call self, h

  walkItHuman: (i, j, i2, j2, k) ->

    if @buffer.length > 0
      h = @buffer.pop()
    else
      h = @create()
      h = @buffer.pop()

    self = @

    $.when( h.walk( i, j, i2, j2, k ) ).done () ->
      self.clear.call self, h

  clear: ( h ) ->
    h.clear()

    @buffer.push h
    @onTheMove--

  walk: (i, j, k) ->
    @onTheMove++
    [i2, j2] = @events.game.map.directionModificators i, j, k
    @walkItHuman i, j, i2, j2, k

  tick: () ->
    @stage.update()

window.S.People = People
