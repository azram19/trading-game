class UI extends S.Drawer
  constructor: ( @events, @minRow, @maxRow ) ->
    canvas = document.getElementById "UI"
    @stage = new Stage canvas
    @stage.autoclear = false

    super @minRow, @maxRow

    @canvasContainer = $( "#canvasWrapper" ).first()

    @canvasDimensions = {}
    @canvasDimensions.x = (@margin-@horIncrement) + @maxRow * @distance
    @canvasDimensions.y = (@margin+@size) + (@diffRows * 2) * @verIncrement

    @setScroller()

    @canvasContainer.find( 'canvas' ).each ( i, el ) =>
      ctx = el.getContext '2d'
      ctx.canvas.width  = @canvasDimensions.x
      ctx.canvas.height = @canvasDimensions.y

    @scrollX= 0
    @scrollY = 0

    $(canvas).bind "contextmenu", @handleClick
    $(this).bind "contextmenu", ( e ) ->
      e.preventDefault()

    $( window ).resize @resizeViewport

    @curMenu = null

  initializeMenus: () ->

    null

  resizeViewport: () =>
    @viewportWidth = viewportHeight = window.innerHeight
    @viewportHeight = viewportWidth = window.innerWidth - 200

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

    @scroller = new Scroller @scroll
    @scroller.setDimensions viewportWidth, viewportHeight, @canvasDimensions.x, @canvasDimensions.y

    @mousedown = false

    @events.trigger 'resize', viewportWidth, viewportHeight

    @canvasContainer.get()[0].addEventListener("mousedown", (e) =>
        @scroller.doTouchStart([{
            pageX: e.pageX
            pageY: e.pageY
        }], e.timeStamp)

        @mousedown = true
    , false)

    document.addEventListener("mousemove", (e) =>
        if not @mousedown
            return

        @scroller.doTouchMove([{
            pageX: e.pageX
            pageY: e.pageY
        }], e.timeStamp)

        @mousedown = true
    , false)

    document.addEventListener("mouseup", (e) =>
        if not @mousedown
          return

        @scroller.doTouchEnd(e.timeStamp)

        @mousedown = false
    , false)

  scroll: (x, y) =>
    @scrollX = x
    @scrollY = y

    @events.trigger 'scroll', x, y


    @canvasContainer.find( 'canvas' ).not( '.noScroll' ).each(
      (i,el) ->
        $el = $ el

        $el.css(
          top: -y
          left: -x
        )
    )


  createMenu: (i, j) ->
    p = @getPoint i, j

    menuStructure = @events.getMenu i, j
    obj = @events.getField i, j

    if not menuStructure?
      return

    menu = new S.RadialMenu @events, @stage.canvas, p.x, p.y, "", "", true, obj

    eventsStructure = S.Types.Events
    submenuNames = @getPrefixes menuStructure

    ( subMenu = @buildMenu submenuName,
        eventsStructure,
        @getWithoutPrefix( submenuName, menuStructure ),
        submenuName

      menu.addChild subMenu
    ) for submenuName in submenuNames

    menu

  #name of the event element, eventsStructure - Types.Events sub object
  #eventsStructure [a:b:c] ...
  buildMenu: ( name, eventsStructure, menuStructure, fullname ) =>

    stName = name[0].toUpperCase() + name[1..]

    title = eventsStructure[stName].title
    desc = eventsStructure[stName].desc

    title ?= ""
    desc ?= ""


    eventsStructure = eventsStructure[stName]
    submenuNames = @getPrefixes menuStructure

    if desc.length > 0 or not submenuNames.length
      m = new S.RadialMenu @events, @stage.canvas, 0, 0, title, desc
      m.setEvent fullname
      console.log fullname

      m
    else
      m = new S.RadialMenu @events, @stage.canvas, 0, 0, title, desc

      (
        subMenu = @buildMenu submenuName,
          eventsStructure,
          @getWithoutPrefix( submenuName, menuStructure ),
          fullname + ':' + submenuName

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
