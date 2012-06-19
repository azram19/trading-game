class Timer
  constructor: ( @events ) ->
    @started = false

    setInterval @tick, 1000

    @counter = new Text()
    @counter.textBaseline  = "middle"
    @counter.textAlign = "center"
    @counter.color = "#fff"
    @counter.font = "bold 32px 'Cabin', Helvetica,Arial,sans-serif"
    @counter.x = 100
    @counter.y = 25

    @canvas = document.getElementById 'timer'
    @stage = new Stage @canvas
    @stage.addChild @counter

  setTime: ( time ) ->
    @time = time

  start:() ->
    @started = true

  stop:() ->
    @started = false

  endOfTime: () ->
    $( @canvas ).remove()
    @stage.removeAllChildren()
    @events.trigger "time:out"

  draw: () ->
    minutes = Math.floor(@time / 60)
    seconds = @time % 60

    if minutes < 10
      minutes = "0#{minutes}"

    if seconds < 10
      seconds = "0#{seconds}"

    if minutes > 0
      text = "#{ minutes }:#{ seconds }"
    else
      text = seconds

    @counter.text = text

  tick:() =>
    if @started
      if @time <= 0
        @endOfTime()
      else if @time <= 60
        @time--
        @draw()
      else
        @time--
        @draw()

      @stage.update()

window.S.Timer = Timer
