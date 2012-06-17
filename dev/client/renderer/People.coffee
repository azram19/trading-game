class People
  constructor: ( @events, options ) ->
    @distance = options.distance
    @time = options.time

    canvas2 = document.getElementById 'animations'
    @stage = new Stage canvas2

    @onTheMove = 0

    @buffer = []
    @moving = {}
    @allHumans = []

    @images = [
      '/img/traggerSprite.png'
    ]

    for i in [0...3]
      @create()

    Ticker.addListener @

    @updateStageThr = _.throttle @updateStage, 50

  updateStage: () ->
    human.tick() for human in @allHumans
    @stage.update()

  create: () ->
    h = new S.Human @events, @images[0], @stage, @distance, @time
    @buffer.push h
    @allHumans.push h

  transfer: ( h, i, j, i2, j2, k ) ->
    key = "#{i}:#{j}"
    key2 = "#{i2}:#{j2}"

    h.key = key2

    self = @

    #Transfer the human, and reset the situation once it's done
    $.when( h.transfer(i, j, i2, j2, k) ).done () ->
      self.clear.call self, h

    if not @moving[key2]?
      @moving[key2] = []

    @moving[key2].push h

  walkItHuman: (i, j, i2, j2, k) ->

    key = "#{i}:#{j}"
    key2 = "#{i2}:#{j2}"
    #1 transfer
    #2 get from buffer
    #3 create
    transferOptions = []# @moving[key]

    #Remove all opitions that are furthere then 5% from their target
    transferOptions = _.filter transferOptions, ( v ) =>
      v.distance < @distance/4

    if transferOptions? and transferOptions.length > 0
      #Get a human closest to the target
      console.log "[People] Found a human :D"

      h = _.chain( transferOptions )
        .sortBy( ( v ) -> -v.distance )
        .first()
        .value()

      #Remove it from the list
      @moving[key] = _.without @moving[key], h

      #Transfer
      @transfer h, i, j, i2, j2, k

      return
    else if @buffer.length > 0
      h = @buffer.pop()
    else
      h = @create()
      h = @buffer.pop()

    h.key = key2

    if not @moving[key2]?
      @moving[key2] = []

    @moving[key2].push h

    self = @

    $.when( h.walk( i, j, i2, j2, k ) ).done () ->
      self.clear.call self, h

  clear: ( h ) ->
    key = h.key
    @moving[key] = _.without @moving[key], h

    h.clear()
    h.key = "-1"

    @buffer.push h

  walk: (i, j, k) ->
    [i2, j2] = @events.game.map.directionModificators i, j, k
    @walkItHuman i, j, i2, j2, k

  tick: () ->
    @updateStageThr()

window.S.People = People
