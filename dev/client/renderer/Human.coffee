class Human
  constructor: ( @events, image, @stage, @walkDistance, @timeForAWalk ) ->
    @ready = new $.Deferred()
    @tranferable = new $.Deferred()
    @walked = new $.Deferred()

    @animation = null
    @currentAnimation = null
    @distance = 0

    myImage = new Image()
    myImage.onload = =>
      @ready.resolveWith @
    myImage.src = image

    @vx = 0
    @vy = 0

    @data =
      images : [myImage]
      frames :
        width : 42
        height : 42
        regX: 21
        regY: 30
      animations :
        stand0 : [0]
        stand1 : [5]
        stand2 : [10]
        stand3 : [15]
        stand4 : [20]
        stand5 : [25]
        walk0 :
          frames : [1, 2, 3, 4]
          next : "walk0"
          frequency: 4
        walk1 :
          frames : [6, 7,8, 9]
          next: "walk1"
          frequency: 4
        walk2 :
          frames : [11, 12, 13, 14]
          next: "walk2"
          frequency: 4
        walk3 :
          frames : [16, 17, 18, 19]
          next: "walk3"
          frequency: 4
        walk4 :
          frames : [21, 22, 23, 24]
          next : "walk4"
          frequency: 4
        walk5 :
          frames : [26, 27, 28, 29]
          next : "walk5"
          frequency: 4

    $.when( @ready ).then ->
      console.log "[Human] ready"
      @spriteSheet = new SpriteSheet @data
      @animation = new BitmapAnimation @spriteSheet
      @stage.addChild @animation

      Ticker.addListener @

  clear: () ->

  walk: ( i, j, i2, j2 ) ->
    $.when( @ready ).then ->
      k = @events.game.map.directionGet i, j, i2, j2

      p1 = @events.ui.getPoint i, j
      p2 = @events.ui.getPoint i2, j2

      @animation.gotoAndPlay "walk" + k

      turns = (@timeForAWalk / Ticker.getInterval())

      dx = p2.x - p1.x
      dy = p2.y - p2.y

      @vx = dx/turns
      @vy = dy/turns

      @move = true

  appear: (i , j, k) ->
    $.when( @ready ).then ->
      if not k?
        k = 0

      p = @events.ui.getPoint i, j
      @animation.x = p.x
      @animation.y = p.y
      @animation.visible = true

      @animation.gotoAndStop "stand" + k

      @stage.update()

  tick: () ->
    if @move
      @animation.x += @vx
      @animation.y += @vy
      @distance += Math.sqrt( @vx*@vx + @vy*@vy )

      if @distance > @walkDistance
        @distance = 0
        @move = false
        @animation.visible = false

window.S.Human = Human
