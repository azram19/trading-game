class UI extends S.Drawer
  constructor: ( @events, @minRow, @maxRow ) ->
    canvas = document.getElementById "UI"
    @stage = new Stage canvas
    @stage.autoclear = false

    canvas.onclick = @handleClick

    super @stage, @minRow, @maxRow

    @curMenu = null

  initializeMenus: () ->

    null

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

    if @curMenu? and @curMenu.hitTest x, y, true
      return
    else
      p = @getCoords (new Point x, y)

      @handleClickOnField p.x, p.y

  handleClickOnField: ( i, j ) =>
    if @curMenu?
      @destroyMenu @curMenu

    @curMenu = @createMenu i, j

    if @curMenu?
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
