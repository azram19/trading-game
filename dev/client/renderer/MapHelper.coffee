class MapHelper extends S.Drawer
  constructor: ( @events, @minRow, @maxRow ) ->
    @canvas = document.getElementById "helpers"
    @stage = new Stage @canvas
    @stage.mouseEventsEnabled = true
    @stage.enableMouseOver 20

    super @minRow, @maxRow

    @colours =
      positive: "rgba(0,255,0,0.4)"
      negative: "rgba(255,0,0,0.4)"
      over: "rgba(255,255,255,0.3)"
      stroke: "rgba(0,0,0,0.8)"

    _.extend @, Backbone.Events

    @overlay = new Shape()
    @overlay.graphics
      .beginFill( "rgba(0,0,0,0.4)" )
      .drawRect( 0, 0, @canvasDimensions.x, @canvasDimensions.y )
      .endFill()

    @stage.addChild @overlay

    @overlay.visible = false

    @fieldsObjs = {}

    $(this).bind "contextmenu", ( e ) ->
      e.preventDefault()
    $(@canvas).bind "contextmenu", ( e ) ->
      e.preventDefault()

    @helpers =
      routing:
        acceptShow: ( io, jo ) ->
          tr = @drawHex io+3, jo, 0, @colours.positive, @colours.stroke
          tr.onClick = @accept
          tr.onMouseOver = null
          tr.onMouseOut = null

          @stage.addChild tr
        show: ( io, jo ) ->

            field = @currentMenu.obj
            for z in [0...6]
              [i, j] = @getIJ io, jo, z

              @state = field.platform.state.routing

              if @state[z].in
                color = @colours.positive
              else
                color = @colours.negative

              k = (5-z)%6

              tr = @drawHalfHex i, j, k, color, @colours.stroke
              tr.z = z

              @fieldsObjs[i+":"+j+":"+k] = tr
              @stage.addChild tr

              if @state[z].out
                color = @colours.positive
              else
                color = @colours.negative

              tr = @drawHalfHex i, j, (k+3), color, @colours.stroke
              tr.z = z

              @fieldsObjs[i+":"+j+":"+(k+3)] = tr
              @stage.addChild tr

            @helpers.routing.acceptShow.call @, io, jo
        over: ( i, j, k ) ->
          field = @currentMenu.obj

          tr = @fieldsObjs[i+":"+j+":"+k]
          z = tr.z

          kIn = (5-z)%6

          if k == kIn
            if @state[z].in
              color = @colours.negative
            else
              color = @colours.positive
          else
            if @state[z].out
              color = @colours.negative
            else
              color = @colours.positive

          @drawHalfHex i, j, k, color, @colours.stroke, tr

        out: ( i, j, k ) ->
          field = @currentMenu.obj

          tr = @fieldsObjs[i+":"+j+":"+k]
          z = tr.z

          kIn = (5-z)%6

          if k == kIn
            if @state[z].in
              color = @colours.positive
            else
              color = @colours.negative
          else
            if @state[z].out
              color = @colours.positive
            else
              color = @colours.negative

          @drawHalfHex i, j, k, color, @colours.stroke, tr

        click: ( i, j, k ) ->
          tr = @fieldsObjs[i+":"+j+":"+k]

          z = tr.z
          kIn = (5-z)%6

          if k == kIn
            if @state[z].in
              @state[z].in = false
              color = @colours.negative
            else
              @state[z].in = true
              color = @colours.positive
          else
            if @state[z].out
              @state[z].out = false
              color = @colours.negative
            else
              color = @colours.positive
              @state[z].out = true

          @drawHalfHex i, j, k, color, @colours.stroke, tr

        generateArguments: ( io, jo, i, j, k ) ->
          routing = @state
          @state = null

          [@currentMenu.obj, routing]

      build:
        platform:
          show: ( io, jo ) ->
            @accept io, jo, 0
          generateArguments: ( io, jo, i, j, k ) ->
            field = @currentMenu.obj

            if field.platform.type?
              owner = field.platform.state.owner

            if not owner?
              (
                owner = channel.state.owner
                break
              ) for id, channel of field.channels

            [io, jo, S.Types.Entities.Platforms.Normal, owner]
        channel:
          show: ( io, jo ) ->
            for z in [0...6]
              [i, j] = @getIJ io, jo, z
              h = @drawHex i, j, 0, "rgba(255,0,0,0.6)", @colours.stroke
              @fieldsObjs[i+":"+j] = h
              @stage.addChild h

            @update = true

          #io, jo - coordinates of the root
          #i, j  coordinates of the clicked hex
          #k - triangle
          generateArguments: ( io, jo, i, j, k ) ->
            field = @currentMenu.obj
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
            color = "rgba(255,255,255,0.8)"

            h = @fieldsObjs[i+":"+j]
            @drawHex i, j, 0, "#fff", color, h

          out: ( i, j, k ) ->
            color = "rgba(0,0,0,0.9)"

            h = @fieldsObjs[i+":"+j]
            @drawHex i, j, 0, "rgba(255,0,0,0.6)", color, h

          click: ( i, j, k ) ->
            @accept( i, j, k )

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

  drawHalfHex: ( i, j, k, fill, stroke, hh ) ->
    if hh?
      halfHex = hh
    else
      halfHex = new Shape()

    g = halfHex.graphics
    g.clear()

    p = @getPoint i, j

    x1 = @size * Math.sin k*Math.PI/3
    y1 = @size * Math.cos k*Math.PI/3

    x2 = @size * Math.sin (k+1) * Math.PI/3
    y2 = @size * Math.cos (k+1) * Math.PI/3

    x3 = @size * Math.sin (k+2) * Math.PI/3
    y3 = @size * Math.cos (k+2) * Math.PI/3

    x4 = @size * Math.sin (k+3) * Math.PI/3
    y4 = @size * Math.cos (k+3) * Math.PI/3


    g.beginStroke( stroke )
      .beginFill( fill )
      .lineTo( x1, y1 )
      .lineTo( x2, y2 )
      .lineTo( x3, y3 )
      .lineTo( x4, y4 )
      .lineTo( 0, 0 )
      .closePath()
      .endFill()
      .endStroke()

    halfHex.x = p.x
    halfHex.y = p.y

    halfHex.onMouseOver = () => @overField i, j, k
    halfHex.onMouseOut = () => @outField i, j, k
    halfHex.onClick = () => @clickField i, j, k

    halfHex

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

  accept: ( i, j, k ) =>
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
      hex.onMouseOut = null ) for hex in @fieldsObjs

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
