class radialMenu
  event: ""

  desc: ""
  text: ""

  expanded: false
  expandedChildren: false
  visible: false

  constructor: ( @engine, @canvas, @x, @y, @text, @desc, @root, @obj ) ->

    @menuId = _.uniqueId()

    @positive_action = 'Yes'
    @negative_action = 'No'
    @event = 'yes'

    ###
    Get the context and stage we will be drawing to. Only for the root it will be the actuall context, for every other element it will get
    overwritten by root's context and stage.
    ###
    @stage = new Stage @canvas
    @stage.autoClear = true

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
    @showTime = 200

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

    #Children elements - class radialMenu
    @children = []

    @initializeDOM = _.once () =>
      ###
      This is a title displayed next to the menu item. It is hidden by
      default and shown only when menu item is in visibile state
      ###
      @$title = new Text @text,
        "13px 'Cabin', Helvetica,Arial,sans-serif",
        "#AAA"

      @$title.visible = false

      @$actionTitle = new Text @positive_action,
        "13px 'Cabin', Helvetica,Arial,sans-serif",
        "#AAA"

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

    @children.push menu

  action: () =>
    console.log "trigger " + @event
    @engine.trigger @event, @obj

  setEvent: ( ev ) ->
    console.debug ev
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

    @button.onClick = @click

    @circle = new Shape()
    @circle.visible = false
    @circle.graphics
      .setStrokeStyle(1)
      .beginStroke( "rgba(0,0,0,#{@fadedOutOpacity})" )
      .drawCircle( @x_o, @y_o, @expand_length )

    @circleC = new Shape()
    @circleC.visible = false
    @circleC.graphics
      .setStrokeStyle(1)
      .beginStroke( "rgba(0,0,0,#{@fadedOutOpacity})" )
      .drawCircle( @x_o, @y_o, @compact_length )

    @actionButton = new Shape()

    if @children.length < 1
      @actionButton =  @drawButtonOrange @actionButton
      @actionButton.y += 40

    P = @button.localToGlobal @x_o, @y_o

    @initializeDOM()

    @$title.x = 15

    @$actionTitle.x = 15
    @$actionTitle.y = 35

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
    @button.visible = true

  hide: () =>
    @showing = false
    @hiding = true

    x = 0
    y = 0

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

  click: () =>
    if not @expanded
      @expand true #show my children

      if not @root
        @parent.collapseChildren @

        if @children.length < 1
          if not @descDisplayed
            console.log 'd'
            @parent.displayText @
          else
            console.log 'und'
            @parent.undisplayText @
    else
      if @children.length < 1
        if not @descDisplayed
          console.log 'd'
          @parent.displayText @
        else
          console.log 'und'
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

window.S.radialMenu = radialMenu

$ ->
  canvas = document.getElementById "radial"
  if canvas?
    window.Mouse = new MouseClass canvas

    window.r = r = new radialMenu null, canvas, 250, 250, "piesek", "", true



    rd5 = '<p>"No more, Queequeg," said I, shuddering; "that will do;" for I knew the inferences without his further hinting them. I had seen a sailor who had visited that very island, and he told me that it was the custom, when a great battle had been gained there, to barbecue all the slain in the yard or garden of the victor; and then, one by one, they were placed in great wooden trenchers, and garnished round like a pilau, with breadfruit and cocoanuts; and with some parsley in their mouths, were sent round with the victors compliments to all his friends, just as though these presents were so many Christmas turkeys.</p>'
    rd6 = "<p>Her power of repulsion for the planet was so great that it had carried her far into space, where she can be seen today, by the aid of powerful telescopes, hurtling through the heavens ten thousand miles from Mars; a tiny satellite that will thus encircle Barsoom to the end of time.</p>"
    rd7 = '<p>"It was in the summer of 2013 that the Plague came. I was twenty-seven  years old, and well do I remember it. Wireless despatches&mdash;"</p>

      <p>Hare-Lip spat loudly his disgust, and Granser hastened to make amends.</p>"'
    rd8 = "<p>Her power of repulsion for the planet was so great that it had carried her far into space, where she can be seen today, by the aid of powerful telescopes, hurtling through the heavens ten thousand miles from Mars; a tiny satellite that will thus encircle Barsoom to the end of time.</p>"
    rd9 = "<p>Her power of repulsion for the planet was so great that it had carried her far into space, where she can be seen today, by the aid of powerful telescopes, hurtling through the heavens ten thousand miles from Mars; a tiny satellite that will thus encircle Barsoom to the end of time.</p>"

    r2 = new radialMenu null, canvas, 0, 0, "kotek", rd5
    r3 = new radialMenu null, canvas, 0, 0, "malpka", rd5
    r4 = new radialMenu null, canvas, 0, 0, "ptaszek", rd5
    r0 = new radialMenu null, canvas, 0, 0, "dziubek", rd5

    r5 = new radialMenu null, canvas, 0, 0, "gawron", rd5
    r6 = new radialMenu null, canvas, 0, 0, "slon", rd6
    r7 = new radialMenu null, canvas, 0, 0, "dzwon", rd7
    r8 = new radialMenu null, canvas, 0, 0, "dzwon1", rd8
    r9 = new radialMenu null, canvas, 0, 0, "dzwon2", rd9

    r.addChild r2
    r.addChild r3
    r.addChild r4
    r.addChild r0

    r4.addChild r5
    r4.addChild r6
    r4.addChild r7
    r4.addChild r8
    r4.addChild r9

    Ticker.setFPS 60

    r.drawIt()
    r.show()

window.radialMenu = radialMenu

