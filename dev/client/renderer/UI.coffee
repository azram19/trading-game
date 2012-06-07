class UI extends S.Drawer
  constructor: ( @minRow, @maxRow, @engine ) ->
    canvas = document.getElementById "UI"
    @stage = new Stage canvas
    @stage.autoclear = false
    @stage.onClick = @handleClick

    super @stage, @minRow, @maxRow


    @curMenu = null

    @engine =
      getMenu:() ->
        [
          'pies:kot:leszek',
          'pies:malpa:swinka',
        ]
      getField: () ->
        {}

    window.Types.Events =
        pies:
          title: 'seip'
          kot:
            title: 'tok'
            leszek:
              title: 'keszel'
              desc: 'fucking mock object'
          malpa:
            title: 'aplam'
            swinka:
              title: 'akniws'
              positive: 'Buy'
              desc: 'very interesting creature'

  initializeMenus: () ->

    null

  createMenu: (i, j) ->
    p = @getPoint i, j

    menuStructure = @engine.getMenu i, j

    obj = @engine.getField i, j
    menu = new S.radialMenu null, @stage.canvas, p.x, p.y, "", "", true, obj

    eventsStructure = window.Types.Events
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

    title = eventsStructure[name].title
    desc = eventsStructure[name].desc

    title ?= ""
    desc ?= ""

    if desc.length > 0
      m = new S.radialMenu null, @stage.canvas, 0, 0, title, desc
      m.setEvent fullname

      m
    else
      m = new S.radialMenu null, @stage.canvas, 0, 0, title, desc

      eventsStructure = eventsStructure[name]
      submenuNames = @getPrefixes menuStructure

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

  handleClick: ( event ) ->
    p = @getCoords event.stageX, eventStageY

    @handleClickOnField p.x, p.y

  handleClickOnField: ( i, j ) =>
    (menu?.hide() for menu in menuI) for menuI in @menus

    @curMenu = createMenu i, j
    @curMenu.click()


  render: (i,j) ->
    menu = createMenu i, j
    menu.drawIt()
    menu.show()

    console.log "Rendering finished"

window.S.UIClass = UI
