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
    @context2d = @canvas.getContext '2d'
    @stage = new Stage @canvas

    @x ?= 0
    @y ?= 0

    @x_origin = @x
    @y_origin = @y

    @length = 120
    @radius = 40

    @alpha = Math.PI / 3
    @beta = Math.PI * 2/2

    @children = []

  addChild: ( menu ) ->
    menu.setXO @x
    menu.setYO @y
    menu.stage = @stage
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
    line = new Shape()
    line.graphics
      .setStrokeStyle( 2 )
      .beginStroke( "white" )
      .moveTo( @x_origin, @y_origin )
      .lineTo( @x, @y )

    @stage.addChild line

    @drawAsRoot()

  drawAsRoot: () =>
    @button = new Shape()
    @button.graphics
      .beginStroke( "red" )
      .beginFill( "red" )
      .drawCircle( @x, @y, @radius )

    console.debug [@x, @y, @x_origin, @y_origin]

    @stage.addChild @button
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
  
  expandChild: ( child ) ->
    child.expand()
    c.compact() for c in @children
    @expandedChildren = true

  compact: () ->
    @hideChildren()
    @expanded = false

    #TODO

  compactChildren: () ->
    c.compact() for c in @children
    @expandedChildren = false

  hide: () ->
    @hideChildren()

    #TODO
  
  hideChildren: () ->
    c.hide() for c in @children
    null

  click: () =>
    if @engine? and @event
      @engine.trigger @event

  tick: ( time ) =>

$ ->
  canvas = document.getElementById "radial"
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