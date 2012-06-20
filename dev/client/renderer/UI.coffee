class UI extends S.Drawer
  constructor: ( @events, @minRow, @maxRow ) ->
    @canvas = document.getElementById "UI"
    @stage = new Stage @canvas
    @stage.autoclear = false

    super @minRow, @maxRow

    @canvasContainer = $( "#canvasWrapper" ).first()

    @setScroller()

    @scrollX = 0
    @scrollY = 0

    @bubble = []

    @resourcesTemplate = Handlebars.templates.resources

    @resizeViewport()

  start: () =>
    viewportHeight = window.innerHeight
    viewportWidth = window.innerWidth - 200

    #start scroller
    @mousedown = false

    @events.trigger 'resize', viewportWidth, viewportHeight

    scrollerDown = ( e ) =>
      @scroller.doTouchStart([{
            pageX: e.pageX
            pageY: e.pageY
        }], e.timeStamp)

      @mousedown = true

    scrollerMove = ( e ) =>
      if not @mousedown
            return

      @scroller.doTouchMove([{
          pageX: e.pageX
          pageY: e.pageY
      }], e.timeStamp)

      @mousedown = true

    scrollerUp = ( e ) =>
      if not @mousedown
        return

      @scroller.doTouchEnd(e.timeStamp)

      @mousedown = false

    @canvasContainer.get()[0].addEventListener("mousedown", scrollerDown , false)
    document.addEventListener("mousemove", scrollerMove, false)
    document.addEventListener("mouseup", scrollerUp, false)


    #Initialize menus
    @curMenu = null
    @menuHelper = new S.MapHelper @events, @minRow, @maxRow

    #ShowResources
    @showResources()

    #Bind events
    $(@canvas).bind "contextmenu", @handleClick
    $(window).bind "contextmenu", ( e ) ->
      e.preventDefault()

    $( window ).resize @resizeViewport

    #Start listening to the ticker
    Ticker.addListener @


  getLoadingStage: ( @loading ) ->
  setLoadingStage: ( @loading ) ->

  gameOver: () ->
    $( '<div id="gameover"><h1>Game Over</h1></div>' )
      .appendTo( '#canvasWrapper' )

  gameTied: () ->
    $( '<div id="gameover"><h1>Game Tied</h1></div>' )
      .appendTo( '#canvasWrapper' )

  gameWon: () ->
    $( '<div id="gameover"><h1>You won</h1></div>' )
      .appendTo( '#canvasWrapper' )

  showTextBubble: ( text, x, y, options ) ->
    config =
      vy: 100
      vx: 0
      t: 1000
      color: [255, 255, 255, 1]

    _.extend config, options

    i  = -1

    _.each @bubble, ( b, k ) ->
      if b.animate == false
        i = k
        return {}

    if i < 0
      bubble = new Text()
      bubble.textAlign = 'center'
      bubble.baseline = ''
      bubble.font = "bold 13px 'Cabin', Helvetica,Arial,sans-serif"
      bubble.color = config.color
      @stage.addChild bubble
      @bubble.push bubble

      i = @bubble.length - 1

    bubble = @bubble[i]
    tInv = config.t/Ticker.getInterval()

    bubble.alpha = 1

    [r,g,b,a] = config.color
    bubble.color = "rgba(#{ r },#{ g },#{ b },#{ a })"
    bubble.c = config.color

    bubble.text = text
    bubble.x = x
    bubble.y = y
    bubble.valpha = 1/tInv
    bubble.vx = config.vx/tInv
    bubble.vy = config.vy/tInv
    bubble.t = config.t
    bubble.visible = true
    bubble.animate = true

    @stage.update()

  tick: () ->
    interval = Ticker.getInterval()
    update = false

    (
      if bubble.animate == true
        if bubble.t > 0

          [r,g,b,a] = bubble.c
          a -= bubble.valpha
          a = Math.max a, 0

          bubble.color = "rgba(#{ r },#{ g },#{ b },#{ a })"
          bubble.c = [r,g,b,a]

          bubble.x -= bubble.vx
          bubble.y -= bubble.vy
          bubble.t -= interval
        else
          bubble.animate = false
          bubble.visible = false

        update = true
    ) for bubble in @bubble

    if update
      @stage.update()

  initializeMenus: () ->

    null

  resizeViewport: () =>
    $chat = $ '#chat'

    @viewportHeight = viewportHeight = window.innerHeight
    @viewportWidth = viewportWidth = window.innerWidth - $chat.outerWidth()

    maxChatWidth = window.innerWidth - @canvasDimensions.x - 18
    console.log maxChatWidth, 300, window.innerWidth, @canvasDimensions.x, 18

    if maxChatWidth > 300
      $chat.width maxChatWidth

      @viewportWidth = viewportWidth = window.innerWidth - $chat.outerWidth()

      @canvasContainer.css(
        height: viewportHeight
        width: viewportWidth
        overflow: 'hidden'
      ).first()
    else
      $chat.width 300

      @viewportWidth = viewportWidth = window.innerWidth - $chat.outerWidth()

      @canvasContainer.css(
        height: viewportHeight
        width: viewportWidth
        overflow: 'hidden'
      ).first()

    @scroller.setDimensions viewportWidth, viewportHeight, @canvasDimensions.x, @canvasDimensions.y

    @events.trigger 'resize', viewportWidth, viewportHeight

  setScroller: () ->
    viewportHeight = window.innerHeight
    viewportWidth = window.innerWidth - 200

    @canvasContainer.css(
      height: viewportHeight
      width: viewportWidth
      overflow: 'hidden'
    ).first()

    @scroller = new Scroller @scroll, {
        locking:false
        bouncing:true
        animating:true
    }
    @scroller.setDimensions viewportWidth, viewportHeight, @canvasDimensions.x, @canvasDimensions.y


  scroll: (x, y) =>
    @scrollX = x
    @scrollY = y

    @events.trigger 'scroll', x, y

    @canvasContainer.find( 'canvas, .scrollIt' ).not( '.noScroll' ).each(
      (i,el) ->
        $el = $ el

        top = -y
        left = -x

        $el.css(
          top: top
          left: left
        )
    )

  showResources: ( amount, type ) ->
    resources = @events.myPlayer.resources

    if not @$html?
      resources = _.map resources, (v, k) ->
        name : k
        value: v
      html = @resourcesTemplate resources: resources
      @$html = $( html ).appendTo '#canvasWrapper'
    else
      name = S.Types.Resources.Names[type-6]
      value = resources[name]
      console.log "[UI] resources", amount, type, value, name
      @$html.find( ".res-#{name}" ).html( name + " : " + value )

  createMenu: (i, j) ->
    p = @getPoint i, j

    menuInfo = @events.getMenu i, j
    obj = @events.getField i, j

    listOfOwnership = @events.renderer.boardDR.roads

    mine = _.find listOfOwnership, ( v ) ->
      [i2, j2] = v
      i2 == i and j2 == j
    #console.log "CHUJEMUJE", @events.renderer.boardDR.owner[i]?[j]?, @events.renderer.boardDR.ownership
    if not menuInfo? or not mine? or (@events.renderer.boardDR.owner[i]?[j]? and not @contains @events.renderer.boardDR.ownership, [i,j])
      return

    console.log "[UI]", i, j, menuInfo, obj

    [menuStructure, menuValidFields] = menuInfo

    menuDesc = _.find menuStructure, ( menu ) ->
      menu.search( "/:*" ) == 0

    menuDesc =
      if menuDesc?
        menuStructure = _.without menuStructure, menuDesc
        menuDesc.substring 2
      else
        null

    menuSpDisplay = _.find menuStructure, ( menu ) ->
      menu.search( "/!*" ) == 0

    menuSpDisplay =
      if menuSpDisplay?
        menuStructure = _.without menuStructure, menuSpDisplay
        menuSpDisplay.substring 2
      else
        null

    menu = new S.RadialMenu @events, @stage.canvas, p.x, p.y, "", "", true, obj

    eventsStructure = S.Types.Events
    submenuNames = @getPrefixes menuStructure

    ( subMenu = @buildMenu submenuName,
        eventsStructure,
        @getWithoutPrefix( submenuName, menuStructure ),
        submenuName,
        menuStructure,
        menuValidFields,
        i,
        j,

      menu.addChild subMenu
    ) for submenuName in submenuNames

    menu.setActionHelper @menuHelper

    if menuSpDisplay?
      displayHelper = new S.MenuDisplayHelper( @events, menuSpDisplay, menu, i, j, p.x, p.y )

      menu.setDisplayHelper displayHelper
      displayHelper.start()

    menu.setObj obj
    menu.setRoot menu

    menu

  #name of the event element, eventsStructure - Types.Events sub object
  #eventsStructure [a:b:c] ...
  buildMenu: ( name, eventsStructure, menuStructure, fullname, fullStructure, validFields, i, j ) =>
    p = @getPoint i, j

    stName = name[0].toUpperCase() + name[1..]

    title = eventsStructure[stName].title
    desc = eventsStructure[stName].desc
    price = eventsStructure[stName].cost

    console.log name, stName, price, fullname, eventsStructure

    title ?= ""
    desc ?= ""

    eventsStructure = eventsStructure[stName]
    submenuNames = @getPrefixes menuStructure

    if desc.length > 0 or not submenuNames.length
      m = new S.RadialMenu @events, @stage.canvas, 0, 0, title, desc
      m.setEvent fullname

      if price?
        displayHelper = new S.MenuDisplayHelper( @events, 'price', m, i, j, p.x, p.y )
        displayHelper.setData price

        m.setDisplayHelper displayHelper
        displayHelper.start()

      index = _.indexOf fullStructure, fullname
      m.setValidFields validFields[index]

      m
    else
      m = new S.RadialMenu @events, @stage.canvas, 0, 0, title, desc

      (
        subMenu = @buildMenu submenuName,
          eventsStructure,
          @getWithoutPrefix( submenuName, menuStructure ),
          fullname + ':' + submenuName,
          fullStructure,
          validFields,
          i,
          j

        m.addChild subMenu
      ) for submenuName in submenuNames

      m

  #Returns uniq prefixes from a list of strings
  getPrefixes: ( list ) ->
    prefixes = _.chain( list )
                .map(
                  ( el ) ->
                    el.split( ':' )[0]
                ).uniq()
                .filter(
                  ( el ) ->
                    el.length > 0
                ).value()

  #Gets elements from the list with the prefix, and returns thme without it
  getWithoutPrefix: ( prefix, list ) ->
    listWithout = _.chain( list )
                  .filter(
                    ( el ) ->
                      el.split( ':' )[0] is prefix
                  ).map(
                    ( el ) ->
                      els = ( el.split( ':' )[1..] ).join ':'
                  ).filter(
                    ( el ) ->
                      el.length > 0
                  ).value()

  getXY: ( ev ) ->
      totalOffsetX = 0
      totalOffsetY = 0
      canvasX = 0
      canvasY = 0
      currentElement = @stage.canvas

      totalOffsetX += currentElement.offsetLeft
      totalOffsetY += currentElement.offsetTop

      (
          totalOffsetX += currentElement.offsetLeft
          totalOffsetY += currentElement.offsetTop
      ) while currentElement = currentElement.offsetParent

      canvasX = ev.pageX - totalOffsetX
      canvasY = ev.pageY - totalOffsetY

      [canvasX, canvasY]


  handleClick: ( event ) =>
    [x, y] = @getXY event

    if event.button != 2
      return

    p = @getCoords (new Point x, y)

    if @curMenu? and @curMenu.hitTest x, y, true
     if @curMenu.positionI == p.x and @curMenu.positionJ == p.y
        @curMenu.hide @curMenu.destroy
        @curMenu = null
      return
    else
      @handleClickOnField p.x, p.y

    event.preventDefault()

  handleClickOnField: ( i, j ) =>
    if @curMenu?
      @destroyMenu @curMenu

    @curMenu = @createMenu i, j

    if @curMenu?
      @curMenu.positionI = i
      @curMenu.positionJ = j
      @curMenu.show()
      @curMenu.click()

  destroyMenu: ( menu ) ->
    if menu?
      menu.destroy()

  render: (i,j) ->
    menu = @createMenu i, j
    menu.drawIt()
    menu.show()

    console.log "Rendering finished"

window.S.UIClass = UI
