class Human
  constructor: ( @events, image = '/img/traggerSprite.png', stage, @walkDistance = 80, @timeForAWalk = 1000 ) ->
    @uid = _.uniqueId()

    if not stage?
      canvas2 = document.getElementById 'animations'
      @stage = new createjs.Stage canvas2
    else
      @stage = stage

    @ready = new $.Deferred()
    @tranferable = new $.Deferred()
    @walked = new $.Deferred()

    @transferred = false

    @animation = null
    @currentAnimation = null
    @distance = 0


    @hideAtTheEnd = true

    @catchUpDistance = 0
    @catchUpVX = 0
    @catchUpVY = 0

    @visible = false

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
          frequency: 2
        walk1 :
          frames : [6, 7,8, 9]
          next: "walk1"
          frequency: 2
        walk2 :
          frames : [11, 12, 13, 14]
          next: "walk2"
          frequency: 2
        walk3 :
          frames : [16, 17, 18, 19]
          next: "walk3"
          frequency: 2
        walk4 :
          frames : [21, 22, 23, 24]
          next : "walk4"
          frequency: 2
        walk5 :
          frames : [26, 27, 28, 29]
          next : "walk5"
          frequency: 2

    $.when( @ready ).then ->
      console.log "[Human] ready"
      @spriteSheet = new createjs.SpriteSheet @data
      @animation = new createjs.BitmapAnimation @spriteSheet
      @stage.addChild @animation

      createjs.Ticker.addListener @

  clear: () ->

  walk: ( i, j, i2, j2, k ) ->
    if not @visible
      @appear i, j, k

    @walked = new $.Deferred()

    $.when( @ready ).then ->

      k = @events.game.map.directionGet i, j, i2, j2

      p1 = @events.ui.getPoint i, j
      p2 = @events.ui.getPoint i2, j2

      @animation.gotoAndPlay "walk" + k

      turns = @timeForAWalk/(1000/Ticker.getMeasuredFPS())

      dx = p2.x - p1.x
      dy = p2.y - p1.y

      @vx = Math.round dx/turns
      @vy = Math.round  dy/turns

      @distance += @walkDistance

      @move = true

    @walked.promise()

  transfer: ( i, j, i2, j2, k ) ->
    @transferred  = true
    console.log "[Human] transfer", @uid, i, j, i2, j2

    transfer = new $.Deferred()

    $.when( @walked ).done () ->
      @catchUpDistance = @distance
      @catchUpVX = @vx
      @catchUpVY = @vy

      z = @walk i, j, i2, j2, k
      $.when( z ).done () ->
        transfer.resolveWith @

    transfer.promise()

  appear: (i , j, k) ->
    $.when( @ready ).then ->
      if not k?
        k = 0

      p = @events.ui.getPoint i, j
      @animation.x = p.x
      @animation.y = p.y
      @animation.visible = true
      @visible = true

      @animation.gotoAndStop "stand" + k

      @stage.update()

  tick: () ->
    if @move
      @animation.x += @vx
      @animation.y += @vy
      @distance -= Math.sqrt( @vx*@vx + @vy*@vy )

      if @catchUpDistance > 0
        @animation.x += @catchUpVX
        @animation.y += @catchUpVY
        @catchUpDistance -= Math.sqrt( @catchUpVX*@catchUpVX + @catchUpVY*@catchUpVY )

      if @distance <= 0
        @distance = 0
        @move = false

        if not @transferred
          @animation.visible = false
          @visible = false
          @walked.resolveWith @
        else
          @transferred = false
          @walked.resolveWith @

window.S.Human = Human
