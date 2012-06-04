class radialMenu
  event: ""

  description: ""
  text: ""

  expanded: false
  expandedChildren: false
  visible: false

  expandTime: 500
  compactTime: 500
  hideTime: 200
  showTime: 200


  constructor: ( @engine, @canvas, @x, @y, @text, @desc ) ->
    if not @mousedownLister
      @canvas.addEventListener this
      @mousedownListener = true

    @$title = $ "<div/>"
    @$title.text @text
    @$title.appendTo 'body'
    @$title.click =>
      @click()

    @context2d = @canvas.getContext '2d'
    @stage = new Stage @canvas
    @parent = null

    @x ?= 0
    @y ?= 0

    @x_origin = @x
    @y_origin = @y

    @length = 60
    @length_base = 60
    @expand_length = @length_base * 1
    @compact_length = @length_base * 0.5

    @radius = 10
    @radius_base = 10
    @expand_radius = @radius_base * 0.8
    @compact_radius = @radius_base * 0.5

    @alpha = Math.PI / 3
    @beta = Math.PI * 2/2

    @children = []


    @boundaries =
      x: @x - @radius
      y: @y - @radius
      width: @radius * 2
      height: @radius * 2

    @mId = Mouse.register @, @click, ['click']

    Ticker.addListener @, false

  addChild: ( menu ) ->
    menu.setXO @x
    menu.setYO @y
    menu.stage = @stage
    menu.parent = @
    menu.setAngle( menu.getAngle() - @children.length * @alpha )
    menu.computeP()

    @children.push menu

  getX: () ->
    @x
  getY: () ->
    @y

  getXO: () ->
    @x_origin
  getYO: () ->
    @y_origin
  getAngle: () =>
    @beta


  setX: ( x ) ->
    @x = x
  setY: ( y ) ->
    @y = y
  setXO: ( x ) ->
    @x_origin = x
  setYO: ( y ) ->
    @y_origin = y
  setAngle: ( beta ) ->
    @beta = beta

  computeP: ( length ) ->
    if not length?
      length = @length

    @x = @x_origin + length * Math.sin( @beta )
    @y = @y_origin + length * Math.cos( @beta )

  draw: () =>
    redraw = @line?

    if not redraw
      @line = new Shape()

    @line.graphics
      .setStrokeStyle( 2 )
      .beginStroke( "white" )
      .moveTo( @x_origin, @y_origin )
      .lineTo( @x, @y )

    if not redraw
      @stage.addChild @line

    @drawAsRoot()

  drawAsRoot: () =>
    redraw = @button?

    if not redraw
      @button = new Shape()

    @button.graphics
      .beginStroke( "red" )
      .beginFill( "red" )
      .drawCircle( @x, @y, @radius )


    P = @button.localToGlobal @x + 2 * @radius, @y - 10

    @$title.css
      'position': 'absolute'
      'left': P.x
      'top': P.y
      'opacity' : 1
      'cursor' : 'pointer'

    @$title.show()


    if not redraw
      @stage.addChild @button

    @button.visible = true

    if @line?
      @line.visible = true

    #update boundaries
    @boundaries =
      x: @x - @radius
      y: @y - @radius
      width: @radius * 2
      height: @radius * 2

    @stage.update()

  restoreFlags: () =>
    @expanded = false
    @expandedChildren = false
    @visible = false

  drawChildren: () =>
    c.draw() for c in @children

    null

  expand: () ->
    if (@expandSteps > 0 and @expandAnimate) or not @expanded
      if not @expanded
        @expanded = true
        @expandSteps = @expandTime / Ticker.getInterval()
        @expandLengthStep = (@expand_length - @length) / @expandSteps
        @expandRadiusStep = (@expand_radius - @radius) / @expandSteps
        @expandStepCounter = 1
        @expandAnimate = true

      #save original radius of the circle, to restore it later
      radius = @radius

      #compute new coordinates
      @computeP @length + @expandLengthStep * @expandStepCounter

      @button.graphics.clear()
      @line.graphics.clear()

      #compute new radius
      @radius = @radius + @expandRadiusStep * @expandStepCounter

      @draw()

      #restore original radius of the item
      @radius = radius

      @computeP()

      @expandSteps--
      @expandStepCounter++
    else
      @expandAnimate = false
      @length = @expand_length
      @radius = @expand_radius

  expandChild: ( child ) ->
    (
      if c != child
        c.compact()
    ) for c in @children

    child.expand()

    @expandedChildren = true

  compact: () =>
    if (@expandSteps > 0 and @compactAnimate) or @expanded
      #section executed only once at the beginning of an animation
      if @expanded
        #hide my children
        @hideChildren()

        #menu item is in compacted state
        @expanded = false

        #number of steps in which the menu should compact
        @expandSteps = @compactTime / Ticker.getInterval()

        #length and radius step change
        @expandLengthStep = (@length - @compact_length) / @expandSteps
        @expandRadiusStep = (@radius - @compact_radius) / @expandSteps

        #number of steps executed so far + 1
        @expandStepCounter = 1

        #execture compact animation
        @compactAnimate = true

      console.log "Compact tick: " + @expandStepCounter

      #save original radius of the circle, to restore it later
      radius = @radius

      #compute new coordinates
      @computeP @length - @expandLengthStep * @expandStepCounter

      #reset graphics of both elements
      @button.graphics.clear()
      @line.graphics.clear()

      #compute new radius
      @radius = @radius - @expandRadiusStep * @expandStepCounter

      #draw the elements
      @draw()

      #change opacity of the title
      @$title.css
        'opacity' : 0.5

      #restore original radius of the item
      @radius = radius

      #restore original coordinates of the element
      @computeP()

      #change counters
      @expandSteps--
      @expandStepCounter++

    else
      #end the animation
      @compactAnimate = false
      @length = @compact_length
      @radius = @compact_radius

  compactChildren: () ->
    c.compact() for c in @children
    @expandedChildren = false

  hide: () ->
    @hideChildren()

    @button.visible = false
    @$title.hide()

    if @line?
      @line.visible = false
    #TODO

  hideChildren: () ->
    c.hide() for c in @children
    null

  click: () =>

    if @parent?
      @parent.expandChild( @ ) #expand me and collapse my siblings

    @drawChildren() #draw my children
    @drawAsRoot() #draw me

  in: ( x, y ) =>
    @button.hitTest x, y

  tick: ( time ) =>
    if @expandAnimate
      @expand()

    if @compactAnimate
      @compact()

$ ->
  canvas = document.getElementById "radial"
  if canvas?
    window.Mouse = new MouseClass canvas

    window.r = r = new radialMenu null, canvas, 100, 100, "piesek"

    r2 = new radialMenu null, canvas, 0, 0, "kotek"
    r3 = new radialMenu null, canvas, 0, 0, "malpka"
    r4 = new radialMenu null, canvas, 0, 0, "ptaszek"
    r5 = new radialMenu null, canvas, 0, 0, "gawron"
    r6 = new radialMenu null, canvas, 0, 0, "slon"
    r7 = new radialMenu null, canvas, 0, 0, "dzwon"
    r8 = new radialMenu null, canvas, 0, 0, "dzwon1"
    r9 = new radialMenu null, canvas, 0, 0, "dzwon2"

    r.addChild r2
    r.addChild r3
    r.addChild r4
    r4.addChild r5
    r4.addChild r6
    r4.addChild r7
    r4.addChild r8
    r4.addChild r9


    r.drawAsRoot()

