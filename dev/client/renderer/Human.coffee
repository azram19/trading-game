class Human
  constructor: ( @events, image, @stage ) ->
    if not @stage?
      canvas2 = document.getElementById 'animations'
      @stage = new Stage canvas2

    @ready = new $.Deferred()
    @animation = null
    @currentAnimation = null

    myImage = new Image()
    myImage.onload = =>
      @ready.resolveWith @
    myImage.src = image

    @v = 0

    @data =
      images : [myImage]
      frames :
        width : 42
        height : 42
        regX: 21
        regY: 30
      animations :
        stand0 : 0
        stand1 : 5
        stand2 : 10
        stand3 : 15
        stand4 : 20
        stand5 : 25
        walk0 :
          frames : [1, 2, 3, 4, "walk0"]
          frequency: 4
        walk1 :
          frames : [6, 7, 8, 9, "walk1"]
          frequency: 4
        walk2 :
          frames : [11, 12, 13, 14, "walk2"]
          frequency: 4
        walk3 :
          frames : [16, 17, 18, 19, "walk3"]
          frequency: 4
        walk4 :
          frames : [21, 22, 23, 24, "walk4"]
          frequency: 4
        walk5 :
          frames : [25, 26, 27, 28, 29, 30, "walk5"]
          frequency: 4

    $.when( @ready ).then ->
      @spriteSheet = new SpriteSheet @data
      @animation = new BitmapAnimation @spriteSheet
      @stage.addChild @animation

      Ticker.addListener @

  walk: ( k ) ->
    @v = 1
    @direction = Math.PI/3 * (6-k)
    @animation.gotoAndPlay "walk" + k


  appear: (i , j) ->
    p = @events.terrain.getPoint i, j
    @animation.x = p.x
    @animation.y = p.y

    @animation.gotoAndPlay "stand2"
  tick: () ->
    @animation.x += @v
    @animation.y += @v

    @stage.update()

window.S.Human = Human
