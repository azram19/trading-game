class People
  constructor: ( @events ) ->
    canvas2 = document.getElementById 'animations'
      @stage = new Stage canvas2

      @onTheMove = 0

    @buffer = []
    @moving = {}

    @images = [
      '/img/traggerSprite.png'
    ]

    Ticker.addListener @

  create: () ->
    h = new S.Human @events, @images[0], @stage
    @buffer.push h

  transfer: ( h, i, j, i2, j2 ) ->
    key = "#{i}:#{j}"
    key2 = "#{i2}:#{j2}"

    h.key = key2

    h.transfer i, j, i2, j2

    if not @moving[key2]?
      @moving[key2] = []

    @moving[key2].push h

    $.when( h.walked( @ ) ).done () ->
      @clear h

  walkItHuman: (i, j, i2, j2) ->

    key = "#{i}:#{j}"
    key2 = "#{i2}:#{j2}"
    #1 transfer
    #2 get from buffer
    #3 create
    transferOptions = @moving[key]
    if transferOptions? and transferOptions.length > 0
      #Get a human closest to the target
      h = _.chain( transferOptions )
        .sortBy( ( v ) -> -v.t )
        .first()

      #Remove it from the list
      @moving[key] = _.without @moving[key], h

      #Wait until it is ready to be transfered and transfer it
      $.when( h.transferable( @ ) )
        .done () ->
          @transfer h, i, j, i2, j2
      
      return
    else if @buffer.length > 0
      h = @buffer.pop()
    else
      h = @create()
      h = @buffer.pop()

    h.key = key2
    h.walk i, j, i2, j2
    
    if not @moving[key2]?
      @moving[key2] = []

    @moving[key2].push h

    $.when( h.walked( @ ) ).done () ->
      @clear h

  clear: ( h ) ->
    key = h.key
    @moving[key] = _.withou @moving[key], h

    h.clear()
    h.key = "-1"

    @buffer.push h

  walk: (i, j, k) ->
    [i2, j2] = @events.game.map.directionModificators i, j, k
    @walkItHuman i, j, i2, j2

  tick: () ->
    if @onTheMove > 0
      @stage.update()