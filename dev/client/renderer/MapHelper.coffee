class MapHelper extends S.Drawer
  constructor: ( @events, @minRow, @maxRow ) ->
    @canvas = document.getElementById "helpers"
    @stage = new Stage @canvas
    @stage.mouseEventsEnabled = true
    @stage.enableMouseOver 20

    super @minRow, @maxRow

    @cwidth = @canvasDimensions.x
    @cheight = @canvasDimensions.y

    @colours =
      positive: "rgba(0,255,0,0.4)"
      negative: "rgba(255,0,0,0.4)"
      over: "rgba(255,255,255,0.3)"
      stroke: "rgba(0,0,0,0.8)"
      fill: "rgba(255,255,255,0.2)"

    _.extend @, Backbone.Events

    @$overlay = $( @canvas ).css
      background: "rgba(0,0,0,0.7)"

    @$overlay.hide()

    @fieldsObjs = {}

    $(this).bind "contextmenu", ( e ) ->
      e.preventDefault()
    $(@canvas).bind "contextmenu", ( e ) ->
      e.preventDefault()

    @helpers =
      routing:
        show: ( io, jo ) ->
            field = @currentMenu.obj

            for z in [0...6]
              if z in @currentMenu.validFields
                [i, j] = @getIJ io, jo, z

                p = @getPoint i, j

                @state = field.platform.state.routing

                if @state[z].in
                  color = @colours.positive
                else
                  color = @colours.negative

                k = (5-z)%6

                angle = 60 * (z-2)

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

                textContainer = new Container()
                @stage.addChild textContainer
                textContainer.x = p.x
                textContainer.y = p.y
                textContainer.rotation = angle

                text = new Text "in", "bold 13px 'Cabin', Helvetica,Arial,sans-serif", '#fff'
                text.textAlign = 'center'
                text.textBaseline = 'middle'
                text.x = -15
                text.rotation = -angle
                textContainer.addChild text

                text = new Text "out", "bold 13px 'Cabin', Helvetica,Arial,sans-serif", '#fff'
                text.textAlign = 'center'
                text.textBaseline = 'middle'
                text.x = 15
                text.rotation = -angle
                textContainer.addChild text

            @acceptShow.call @, io, jo
            @cancelShow.call @, io, jo
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
            [io, jo, S.Types.Entities.Platforms.Normal, undefined]
        channel:
          show: ( io, jo ) ->
            for z in [0...6]
              if z in @currentMenu.validFields
                [i, j] = @getIJ io, jo, z

                h = @drawHex i, j, 0, @colours.fill, @colours.stroke
                @fieldsObjs[i+":"+j] = h
                @stage.addChild h

            @cancelShow.call @, io, jo

          #io, jo - coordinates of the root
          #i, j  coordinates of the clicked hex
          #k - triangle
          generateArguments: ( io, jo, i, j, k ) ->
            field = @currentMenu.obj
            k = @getK io, jo, i, j

            [field.xy[0], field.xy[1], k, undefined]

          over: ( i, j, k ) ->
            color = "rgba(255,255,255,0.8)"

            h = @fieldsObjs[i+":"+j]
            @drawHex i, j, 0, "#fff", color, h

          out: ( i, j, k ) ->
            color = "rgba(0,0,0,0.9)"

            h = @fieldsObjs[i+":"+j]
            @drawHex i, j, 0,  @colours.fill, color, h

          click: ( i, j, k ) ->
            @accept( i, j, k )

    @.on 'all', @parseAndPrepareEvent

    Ticker.addListener @

  isLegal: ( i, j, ci, cj ) ->

  #Returns direction from i, j to ci, cj
  getK: ( i, j, ci, cj ) ->
    @events.game.map.directionGet i, j, ci, cj

  getIJ: ( i, j, k ) ->
    [mi, mj] = @events.game.map.directionModificators i, j, k

    return [mi, mj]

  acceptShow: ( io, jo ) ->
    c = new Container()

    tr = @drawHex io+3, jo, 0, @colours.positive, @colours.stroke
    tr.onClick = @accept
    tr.onMouseOver = null
    tr.onMouseOut = null

    p = @getPoint io+3, jo
    text = new Text 'Execute', "bold 13px 'Cabin', Helvetica,Arial,sans-serif", '#fff'
    text.textAlign = 'center'
    text.textBaseline = 'middle'
    text.y = p.y
    text.x = p.x
    text.onClick = @cancel

    c.addChild tr
    c.addChild text

    @stage.addChild c

  cancelShow: ( io, jo ) ->
    c = new Container()

    tr = @drawHex io+4, jo, 0, @colours.negative, @colours.stroke
    tr.onClick = @cancel
    tr.onMouseOver = null
    tr.onMouseOut = null

    p = @getPoint io+4, jo
    text = new Text "Cancel", "bold 13px 'Cabin', Helvetica,Arial,sans-serif", '#fff'
    text.textAlign = 'center'
    text.textBaseline = 'middle'
    text.y = p.y
    text.x = p.x
    text.onClick = @cancel

    c.addChild tr
    c.addChild text

    @stage.addChild c

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

    hex.cache(-@horIncrement, -@size, (@distance), (@size)*2)

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

    triangle.cache(-@horIncrement, -@size, (@distance), (@size)*2)

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
      #halfHex.cache 0, 0, @size, @size

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

    halfHex.cache(-@horIncrement, -@size, (@distance), (@size)*2)

    halfHex.x = p.x
    halfHex.y = p.y

    halfHex.onMouseOver = () => @overField i, j, k
    halfHex.onMouseOut = () => @outField i, j, k
    halfHex.onClick = () => @clickField i, j, k

    halfHex

  showOverlay: () ->
    @$overlay.show()

    $( @canvas ).css
      'z-index': 20

  hideOverlay: () ->
    @$overlay.hide()

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

  help: ( event, caller ) =>
    @update = true
    @parseAndPrepareEvent event, caller

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
      @currentDeferr = new $.Deferred()

      @currentHelper = obj
      @i = caller.obj.xy[0]
      @j = caller.obj.xy[1]

      @currentMenu = caller
      @currentEvent = event

      @showOverlay()
      @currentHelper.show.call @, @i, @j

      @currentDeferr.promise()

  clickField: ( i, j, k ) =>
    if @currentHelper?
      @currentHelper.click.call @, i, j, k

  accept: ( i, j, k ) =>
    args = @currentHelper.generateArguments.call @, @i, @j, i, j, k
    args = [@currentEvent].concat args

    @currentDeferr.resolveWith @currentMenu, args

    @clean()
    @close()

  cancel: () =>
    @currentDeferr.rejectWith @currentMenu, [@currentEvent]

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

    @update = false
    @stage.update()

  tick: () ->
    if @update
      @stage.update()

window.S.MapHelper = MapHelper
