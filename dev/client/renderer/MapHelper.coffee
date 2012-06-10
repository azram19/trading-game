class MapHelper extends S.Drawer
  constructor: ( @events, @minRow, @maxRow ) ->
    @canvas = document.getElementById "helpers"
    @stage = new Stage @canvas
    @stage.mouseEventsEnabled = true
    @stage.enableMouseOver 20

    super @minRow, @maxRow

    _.extend @, Backbone.Events

    @overlay = new Shape()
    @overlay.graphics
      .beginFill( "rgba(0,0,0,0.4)" )
      .drawRect( 0, 0, @canvasDimensions.x, @canvasDimensions.y )
      .endFill()

    @stage.addChild @overlay

    @overlay.visible = false

    @triangles = {}
    @hexes = {}

    $(this).bind "contextmenu", ( e ) ->
      e.preventDefault()
    $(@canvas).bind "contextmenu", ( e ) ->
      e.preventDefault()

    @helpers =
      routing:
        show: ( io, jo ) ->
            color = "rbga(0,0,0,0.9)"
            for z in [0...6]
              [i, j] = @getIJ io, jo, z
              for k in [0...6]
                tr = @drawTriangle i, j, k, "rbga(255,0,0,0.6)", color
                @triangles[i+":"+j] = tr
                @stage.addChild tr

        generateArguments: ( io, jo, i, j, k ) ->

      build:
        channel:
          fields: [1, 1, 1, 1, 1, 1, 1]
          show: ( io, jo ) ->
            color = "rbga(0,0,0,0.9)"
            for z in [0...6]
              [i, j] = @getIJ io, jo, z
              h = @drawHex i, j, 0, "rbga(255,0,0,0.6)", color
              @hexes[i+":"+j] = h
              @stage.addChild h

            @update = true

          #io, jo - coordinates of the root
          #i, j  coordinates of the clicked hex
          #k - triangle
          generateArguments: ( io, jo, i, j, k ) ->
            field = @events.getField io, jo
            k = @getK io, jo, i, j

            if field.platform.type?
              owner = field.platform.state.owner

            if not owner?
              (
                owner = channel.state.owner
                break
              ) for id, channel of field.channels

            [field.xy[0], field.xy[1], k, owner]

          over: ( i, j, k ) ->
            color = "rbga(255,255,255,0.8)"

            h = @hexes[i+":"+j]
            @drawHex i, j, 0, "#fff", color, h

          out: ( i, j, k ) ->
            color = "rbga(0,0,0,0.9)"

            h = @hexes[i+":"+j]
            @drawHex i, j, 0, "rbga(255,0,0,0.6)", color, h

          click: ( i, j, k ) ->
            @click( i, j, k )

    @.on 'all', @parseAndPrepareEvent

    Ticker.addListener @

  isLegal: ( i, j, ci, cj ) ->

  #Returns direction from i, j to ci, cj
  getK: ( i, j, ci, cj ) ->
    mi = ci - i
    mj = cj - j

    ks = [
      [-1,-1],
      [0,-1],
      [1,0],
      [1,1],
      [0,1],
      [-1,0]
    ]

    h = _.map ks, ( [mik, mjk], i ) ->
      if mik == mi and mjk == mj
        i
      else
        7

    r = _.find h, ( v, i ) ->
      v != 7

    r

  getIJ: ( i, j, k ) ->
    mi = [-1, 0, 1, 1, 0, -1]
    mj = [-1, -1, 0, 1, 1, 0]

    return [i+mi[k],j+mj[k]]


  drawHex: ( i, j, k, fill, stroke, h ) ->
    if h?
      hex = h
    else
      hex = new Shape()

    g = hex.graphics
    g.clear()

    p = @getPoint i, j

    g.beginStroke( stroke )
      .beginFill( fill )
      .drawPolyStar(0, 0, @size, 6, 0, 90)

    hex.x = p.x
    hex.y = p.y

    hex.onMouseOver = () => @overField i, j, k
    hex.onMouseOut = () => @outField i, j, k
    hex.onClick = () => @clickField i, j, k

    hex

  drawTriangle: ( i, j, k, fill, stroke, tr ) ->
    if tr?
      triangle = tr
    else
      triangle = new Shape()

    g = triangle.graphics
    g.clear()

    p = @getPoint i, j

    x1 = @size * Math.sin k*Math.PI/3
    y1 = @size * Math.cos k*Math.PI/3

    x2 = @size * Math.sin (k+1)*Math.PI/3
    y2 = @size * Math.cos (k+1)*Math.PI/3

    g.beginStroke( stroke )
      .beginFill( fill )
      .lineTo( x1, y1 )
      .lineTo( x2, y2 )
      .lineTo( 0, 0 )
      .closePath()
      .endFill()
      .endStroke()

    triangle.x = p.x
    triangle.y = p.y

    triangle.onMouseOver = () => @overField i, j, k
    triangle.onMouseOut = () => @outField i, j, k

    triangle

  showOverlay: () ->
    @overlay.visible = true

    $( @canvas ).css
      'z-index': 20

  hideOverlay: () ->
    @overlay.visible = false

    $( @canvas ).css
      'z-index': 7

  overField: ( i, j, k ) ->
    if @currentHelper?
      @currentHelper.over.call @, i, j, k

  outField: ( i, j, k ) ->
    if @currentHelper?
      @currentHelper.out.call @, i, j, k

  highlightField: ( i, j ) ->
    if @currentHelper?
      @currentHelper.highlight.call @, i, j

  parseAndPrepareEvent: ( event, caller ) =>
    console.log "map:helper:" + event

    path = event.split ':'

    obj = _.reduce path, ( memo, p ) ->
        if memo[p]?
          memo[p]
        else if memo.show?
          memo
        else null

      , @helpers


    if obj?
      @currentHelper = obj
      @i = caller.obj.xy[0]
      @j = caller.obj.xy[1]

      @currentMenu = caller
      @currentEvent = event

      @showOverlay()
      @currentHelper.show.call @, @i, @j

  clickField: ( i, j, k ) =>
    if @currentHelper?
      @currentHelper.click.call @, i, j, k

  click: ( i, j, k ) =>
    args = @currentHelper.generateArguments.call @, @i, @j, i, j, k
    @currentMenu.trigger "menu:helper:" + @currentEvent, args

    @clean()
    @close()

  cancel: () =>
    @currentMenu.trigger "menu:helper:cancel"

    @clean()
    @close()

  clean: () =>
    (
      hex.clear()
      hex.onClick = null
      hex.onMouseOver = null
      hex.onMouseOut = null ) for hex in @hexes

    (
      triangle.clear()
      triangle.onClick = null
      triangle.onMouseOver = null
      triangle.onMouseOut = null ) for triangle in @triangles

    @currentMenu = null
    @currentEvent = null
    @currentHelper = null

    @stage.removeAllChildren()
    @stage.addChild @overlay

  close: () =>
    @hideOverlay()

    @update = true

  tick: () ->
    @stage.update()

window.S.MapHelper = MapHelper
