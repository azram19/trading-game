class radialMenu
  event: ""

  description: ""
  text: ""

  expanded: false
  expandedChildren: false
  visible: false

  expandTime: 200
  collapseTime: 200
  hideTime: 200
  showTime: 200


  constructor: ( @engine, @canvas, @x, @y ) ->
    if not @mousedownLister
      @canvas.addEventListener
      @mousedownListenerr = true

    @context2d = @canvas.getContext '2d'
    @stage = new Stage @canvas
    @parent = null

    @x ?= 0
    @y ?= 0

    @x_origin = @x
    @y_origin = @y

    @length = 120
    @expand_length = @length * 1
    @compact_length = @length * 0.4

    @radius = 10

    @alpha = Math.PI / 3
    @beta = Math.PI * 2/2

    @children = []

    Mouse.register @, 'click'

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

    console.log redraw

    if not redraw
      @button = new Shape()

    @button.graphics
      .beginStroke( "red" )
      .beginFill( "red" )
      .drawCircle( @x, @y, @radius )

    if not redraw
      @stage.addChild @button

    @button.visible = true

    if @line?
      @line.visible = true

    @stage.update()

  restoreFlags: () =>
    @expanded = false
    @expandedChildren = false
    @visible = false

  drawChildren: () =>
    c.draw() for c in @children

    null

  expand: () ->
    @expanded = true

    @computeP( @expand_length )

    @button.graphics.clear()
    @line.graphics.clear()
    @draw()

    @computeP()

  expandChild: ( child ) ->
    ( if c != child
        c.compact()
      ) for c in @children

    child.expand()

    @expandedChildren = true

  compact: () =>
    @hideChildren()
    @expanded = false

    @computeP( @compact_length )

    @button.graphics.clear()
    @line.graphics.clear()
    @draw()

    @computeP()

    #TODO

  compactChildren: () ->
    c.compact() for c in @children
    @expandedChildren = false

  hide: () ->
    @hideChildren()

    @button.visible = false

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

$ ->
  canvas = document.getElementById "radial"
  window.Mouse = new MouseClass canvas

  window.r = r = new radialMenu null, canvas, 100, 100

  r2 = new radialMenu null, canvas
  r3 = new radialMenu null, canvas
  r4 = new radialMenu null, canvas
  r5 = new radialMenu null, canvas
  r6 = new radialMenu null, canvas
  r7 = new radialMenu null, canvas

  r.addChild r2
  r.addChild r3
  r.addChild r4
  r4.addChild r5
  r4.addChild r6
  r4.addChild r7

  r.drawAsRoot()
