class RadialMenu
  event: ""

  desc: ""
  text: ""

  expanded: false
  expandedChildren: false
  visible: false

  constructor: ( @engine, @canvas, @x, @y, @text, @desc, @root, @obj ) ->

    @menuId = _.uniqueId()

    _.extend @, Backbone.Events

    $( @canvas ).bind "contextmenu", ( e ) ->
      e.preventDefault()

    @positive_action = 'Yes'
    @negative_action = 'No'

    @actionHelper = null
    @displayHelper = null

    ###
    Get the context and stage we will be drawing to. Only for the root it will be the actuall context, for every other element it will get
    overwritten by root's context and stage.
    ###
    @stage = new Stage @canvas
    @stage.autoclear = false

    #Container where we store all our children
    @container = new Container()

    #My parent
    @parent = null

    #Current coordinates
    @x_o = 0
    @y_o = 0

    @x ?= @x_o
    @y ?= @y_o

    ###
    Distances from the origin in different states.
    ###
    @length = 0

    @length_base = 100
    @expand_length = @length_base
    @compact_length = @length_base * 0.5

    #Constants
    @expandTime = 500
    @compactTime = 500
    @hideTime = 200
    @showTime = 50

    @priority = 100

    #Alphas
    @fadedInOpacity = 1
    @fadedOutOpacity = 0.3
    @opacity = 1

    #Flags
    @visible = false
    @descDisplayed = false
    @expanded = false
    @expanding = false #visible -> expanded
    @collapsing = false #expanded -> collapsed
    @showing = false #hidden -> visible
    @hiding = false #visible -> hidden
    @rotating = false

    @drawn = false

    #Radius of the button
    @radius = 10

    #Angles
    @alpha = Math.PI / 6
    @beta = -(Math.PI * 7/6)

    #Children elements - class RadialMenu
    @children = []

    @initializeDOM = _.once () =>
      ###
      This is a title displayed next to the menu item. It is hidden by
      default and shown only when menu item is in visibile state
      ###
      @$title = new Text @text,
        "13px 'Cabin', Helvetica,Arial,sans-serif",
        "#FFF"

      @$title.visible = false

      @$actionTitle = new Text @positive_action,
        "13px 'Cabin', Helvetica,Arial,sans-serif",
        "#FFF"

      @$actionTitle.visible = false

      @$title.onClick = @click
      @$actionTitle.onClick = @action

      @$desc = $ "<div/>"
      @$desc.html @desc
      @$desc.addClass 'radial-menu-desc'
      @$desc.addClass 'hyphenate'
      @$desc.appendTo 'body'

  changeDOM: () ->
    @$title.text = @text
    @$actionTitle.text = @positive_action
    @$desc.html @desc

  addChild: ( menu ) ->
    menu.priority = @priority - 1
    menu.stage = @stage
    menu.parent = @
    menu.beta = menu.beta - @children.length * @alpha
    menu.childIndex = @children.length
    menu.obj = @obj
    menu.actionHelper = @actionHelper

    @children.push menu

  setObj: ( obj ) ->
    @obj = obj

    child.setObj obj for child in @children

  setRoot: ( root ) ->
    @rootElement = root

    child.setRoot root for child in @children

  setDisplayHelper: ( displayHelper ) ->
    @displayHelper = displayHelper

  setActionHelper: ( actionHelper ) ->
    @actionHelper = actionHelper

    child.setActionHelper actionHelper for child in @children

  action: () =>
    if @actionHelper?
      @.on "menu:helper:" + @event, ( helperArgs ) =>
        @.off "menu:helper:" + @event

        myArgs = [@event]
        eventArgs = myArgs.concat helperArgs

        @executeAction.apply @, eventArgs

    @actionHelper.trigger @event, @

    @rootElement.hide @rootElement.destroy

  executeAction: () ->
    console.log arguments
    @engine.trigger.apply @engine, arguments

  actionArgs: () ->

  setEvent: ( ev ) ->
    @event = ev

  setPositiveAction: ( @positive_action ) ->
  setNegativeAction: ( @negative_action ) ->


  computeP: ( length, beta ) ->
    length ?= @length
    beta ?= @beta

    x = length * Math.sin( beta )
    y = length * Math.cos( beta )

    [x,y]

  drawIt: () =>
    @draw()

    c.drawIt() for c in @children

  draw: () =>
    if @drawn
      return false

    @drawn = true

    @button = new Shape()

    @button =
      if @children.length < 1
        @drawButtonBlue @button
      else
        @drawButtonOrange @button

    if not @root
      @button.onClick = @click

    @circle = new Shape()
    @circle.visible = false
    @circle.graphics
      .setStrokeStyle(2)
      .beginStroke( "rgba(0,0,0,#{@fadedOutOpacity})" )
      .drawCircle( @x_o, @y_o, @expand_length )

    @circleC = new Shape()
    @circleC.visible = false
    @circleC.graphics
      .setStrokeStyle(2)
      .beginStroke( "rgba(0,0,0,#{@fadedOutOpacity})" )
      .drawCircle( @x_o, @y_o, @compact_length )

    @actionButton = new Shape()
    @actionButton.onClick = @action

    if @children.length < 1
      @actionButton =  @drawButtonOrange @actionButton
      @actionButton.y += 40

    P = @button.localToGlobal @x_o, @y_o

    @initializeDOM()

    @$title.x = 15
    @$title.y = 5

    @$actionTitle.x = 15
    @$actionTitle.y = 45

    if @root
      @container.addChild @$title
      @container.addChild @$actionTitle
      @stage.addChild @circleC
      @stage.addChild @circle
      @stage.addChild @button
      @stage.addChild @container
    else
      @container.addChild @$title
      @container.addChild @$actionTitle
      @parent.container.addChild @circleC
      @parent.container.addChild @circle
      @parent.container.addChild @button
      @parent.container.addChild @actionButton
      @parent.container.addChild @container


    @button.visible = false
    @actionButton.visible = false

    c.draw() for c in @children

    @button.cache @x_o-@radius, @y_o-@radius, (@radius) * 2, (@radius) * 2
    @actionButton.cache @x_o-@radius, @y_o-@radius, (@radius) * 2, (@radius) * 2

    Ticker.addListener @, false

  destroy: () ->
    child.destroy() for child in @children


    if @displayHelper
      @displayHelper.hide()

    @hideText()
    @button.visible = false
    @container.visible = false

    $( @canvas ).unbind "contextmenu", ( e ) ->
      e.preventDefault()
    Ticker.removeListener @

  drawButtonOrange: ( button ) ->
    button.graphics
      .beginRadialGradientFill(["#F38630","#FA6900", "#222"], [0,0.7,1], @x_o, @y_o, 0, @x_o, @y_o, @radius)
      .drawCircle( @x_o, @y_o, @radius )

    button

  drawButtonBlue: ( button ) ->
    button.graphics
      .beginRadialGradientFill(["#A7DBD8","#69D2E7", "#222"], [0,0.7,1], @x_o, @y_o, 0, @x_o, @y_o, @radius)
      .drawCircle( @x_o, @y_o, @radius )

    button

  restoreFlags: () =>
    @expanded = false
    @expandedChildren = false
    @visible = false

  show: () =>
    if not @drawn
      @draw()

    @showing = true
    @hiding = false

    [x,y] = @computeP @length_base

    if not @root and @x != x and @y != y
      @steps = @showTime/Ticker.getInterval()
      @stepX = (x-@x)/@steps
      @stepY = (y-@y)/@steps
      @stepOpacity = (1-@opacity)/@steps
      @length = @length_base
    else
      @steps = 0
      @stepX = 0
      @stepY = 0
      @stepOpacity = 0

    @$title.visible = true

    if not @root
      @button.visible = true

  hide: ( fn ) =>
    @showing = false
    @hiding = true

    x = 0
    y = 0

    if fn?
      @hideFn = fn
    else
      @hideFn = () ->

    if not @root and @x != x and @y != y
      @steps = @showTime/Ticker.getInterval()
      @stepX = @x/@steps
      @stepY = @y/@steps
      @stepOpacity = (-@opacity)/@steps
    else
      @steps = 0
      @stepX = 0
      @stepY = 0
      @stepOpacity = 0

    @hideChildren()
    @circle.visible = false
    @circleC.visible = false

  hitTest: ( x, y, recursive ) =>
    sq = ( a ) ->
      a * a

    if @circle.visible
      l = @expand_length
    else if @circleC.visible
      l = @compact_length

    rsq = l + 10

    global = @button.parent.localToGlobal @x, @y

    if rsq > 0
      if rsq > Math.sqrt( sq( x - global.x) + sq(y - global.y) )
        return true
      else if recursive
        return _.any( child.hitTest x, y for child in @children )

    false


  expand: ( expandChildren ) =>
    if not @visible
      @show()

    if @children.length > 0
      @circle.visible = true

    @expanding = true
    @collapsing = false

    [x,y] = @computeP @expand_length

    if not @root and @x != x and @y != y
      @steps = @showTime/Ticker.getInterval()
      @stepX = (x-@x)/@steps
      @stepY = (y-@y)/@steps
      @stepOpacity = (@fadedInOpacity-@opacity)/@steps
      @length = @expand_length
    else
      @steps = 0
      @stepX = 0
      @stepY = 0
      @stepOpacity = 0

    if expandChildren
      c.show() for c in @children
      @expanded = true

  collapseChildren: ( child ) =>
    @undisplayText c for c in @children

    (
      if c != child
        c.collapse()

    ) for c in @children

    @circle.visible = true

    if @children.length > 1
      @circleC.visible = true

  hideChildren: () =>
    @expanded = false
    @undisplayText c for c in @children
    c.hide() for c in @children

    @circle.visible = false
    @circleC.visible = false

  collapse: () =>
    @collapsing = true
    @expanding = false

    [x,y] = @computeP @compact_length

    if not @root  and @x != x and @y != y
      @steps = @showTime/Ticker.getInterval()
      @stepX = (@x-x)/@steps
      @stepY = (@y-y)/@steps
      @stepOpacity = (@fadedOutOpacity-@opacity)/@steps
      @length = @compact_length
    else
      @steps = 0
      @stepX = 0
      @stepY = 0
      @stepOpacity = 0

    @hideChildren()
    @circle.visible = false
    @circleC.visible = false

  showAnimate: () =>
    if @steps <= 0
      @showing = false
      @visible = true
      @$title.visible = true
    else
      @steps--
      @x += @stepX
      @y += @stepY
      @opacity += @stepOpacity

  hideAnimate: () =>
    if @steps <= 0
      @hiding = false
      @visible = false
      @$title.visible = false

      if @root
        @hideText()
        @button.visible = false
        @container.visible = false
        @hideFn()
    else
      @steps--
      @x -= @stepX
      @y -= @stepY
      @opacity += @stepOpacity

  collapseAnimate: () =>
    if @steps <= 0
      @collapsing = false
      @expanded = false
    else
      @x -= @stepX
      @y -= @stepY
      @opacity += @stepOpacity
      @steps--

  expandAnimate: () =>
    if @steps <= 0
      @expanding = false
    else
      @x += @stepX
      @y += @stepY
      @opacity += @stepOpacity
      @steps--

  displayText: ( child ) =>
    if child.descDisplayed
      return

    rangePi = ( angle ) ->
      while angle < 0
        angle += (Math.PI*2)
      angle % (Math.PI*2)

    angle = (rangePi child.beta)

    #element is already right - move following siblings
    if angle > (Math.PI/2)-0.2 and angle < (Math.PI/2)+0.2
      child.rotate 0, child.showText

    #element is in fourth quater - rotate down and move following siblings
    else if angle > 0 and angle < Math.PI/2
      rotation = Math.PI/2 - angle
      child.rotate rotation, child.showText

    #element is in first quater - rotate up and move proceding, and following siblings
    else if angle < Math.PI + 0.2 and angle > Math.PI/2
      rotation = (angle - Math.PI/2)
      child.rotate -rotation, child.showText

  undisplayText: ( child ) =>
    if not child.descDisplayed
      return

    child.beta = child.gamma
    child.hideText()

  showText: () =>
    global = @parent.container.localToGlobal @x, @y

    @$desc.css
      top: global.y - 10
      left: global.x + @$title.getMeasuredWidth() + 25

    @$desc.slideDown 200
    @descDisplayed = true
    @actionButton.visible = true
    @$actionTitle.visible = true

  hideText: () =>
    @$desc.hide()
    @descDisplayed = false
    @actionButton.visible = false
    @$actionTitle.visible = false

  rotate: ( angle, fn, full ) =>
    @gamma = @beta
    if not fn?
      fn = () ->

    @rotationFn = fn

    @rotateSteps = @showTime/Ticker.getInterval()
    @rotateStep = angle / @rotateSteps
    @rotateStepXY = full

    if full
      (child.rotate angle, null, true) for child in @children

    @rotating = true

  rotateAnimate: () =>
    if @rotateSteps <= 0
      @rotateStepXY = 0
      @rotationFn()
      @rotationFn = () ->
      @rotating = false
    else
      @beta += @rotateStep

      if @rotateStepXY

        [x,y] = @computeP @length

        if @root
          @x += x
          @y += y
        else
          @x = x
          @y = y

      @rotateSteps--

  click: ( show ) =>
    if not @expanded
      @expand true #show my children

      if not @root
        @parent.collapseChildren @

        if @children.length < 1
          if @desc.length == 0
            @action()
          else if not @descDisplayed
            @parent.displayText @
          else
            @parent.undisplayText @
      else if @displayHelper
        @displayHelper.show()

    else
      if @children.length < 1
        if @desc.length == 0
          @action()
        else if not @descDisplayed
          @parent.displayText @
        else
          @parent.undisplayText @
          @parent.expand true

      @hideChildren()

  in: ( x, y ) =>
    @button.hitTest x, y

  tick: ( time ) =>
    @animating = @rotating or
                  @showing or
                  @hiding or
                  @expanding or
                  @collapsing

    if ( not @drawn or not @animating ) and not @root
      return false

    #perform animations
    if @rotating
      @rotateAnimate()

    if @showing
      @showAnimate()

    if @hiding
      @hideAnimate()

    if @expanding
      @expandAnimate()

    if @collapsing
      @collapseAnimate()

    ###
    Apply new coordinates computated by animating functions
    ###
    @circle.x = @x
    @circle.y = @y

    @circleC.x = @x
    @circleC.y = @y

    @button.x = @x
    @button.y = @y
    @actionButton.x = @x
    @actionButton.y = @y + 40

    @button.alpha = @opacity
    @$title.alpha = @opacity

    if not @root
      @container.x = @x
      @container.y = @y
    else
      @container.x = @x
      @container.y = @y

    ###
    We do not want to update the stage too many times so we call this
    only from the root element of the menu
    ###
    if @root
      @stage.update()

window.S.RadialMenu = RadialMenu
