class GSignal
    tickSizeX: 0
    tickSizeY: 0
    div: 48
    closestDest: {}


    constructor: (@shape, source, dest) ->
        @closestDest = new Point(dest.x - source.x, dest.y - source.y)
        @setRouting()

    setTickSizeX: (t) ->
        @tickSizeX = t
    
    getTickSizeX: () ->
        @tickSizeX
    
    setTickSizeY: (t) ->
        @tickSizeY = t
    
    getTickSizeY: () ->
        @tickSizeY

    setRouting: () ->
        @setTickSizeX(@closestDest.x/@div)
        @setTickSizeY(@closestDest.y/@div)

class BoardDrawer
    margin: 100
    size: 40
    horIncrement: 0
    verIncrement: 0
    diffRows: 0
    signals: {}
    basePoint1: {}
    basePoint2: {}

    constructor: (@id, @stage, @minRow, @maxRow) ->
        @horIncrement = Math.ceil Math.sqrt(3)*@size/2
        @verIncrement = Math.ceil 3*@size/2
        @diffRows = @maxRow - @minRow

        @stage.enableMouseOver()

        @signals = new Container
        @stage.addChild(@signals)

        Ticker.setFPS 50
        Ticker.addListener this

    setSize: (size) ->
        @size = size
    
    setMargin: (margin) ->
        @margin = margin

    getPoint: (i, j) ->
        offset = @margin + Math.abs(@diffRows - j)*@horIncrement
        x = offset + 2*i*@horIncrement
        y = @margin + j*@verIncrement
        new Point(x, y)

    getDestination: (point, dir) ->
        p = new Point(point.x, point.y)
        switch dir
            when 0 then (
                p.x -= @horIncrement
                p.y -= @verIncrement)
            when 1 then (
                p.x += @horIncrement
                p.y -= @verIncrement)
            when 2 then p.x += 2*@horIncrement
            when 3 then (
                p.x += @horIncrement
                p.y += @verIncrement)
            when 4 then (
                p.x -= @horIncrement
                p.y += @verIncrement)
            when 5 then p.x -= 2*@horIncrement
        p

    drawHex: (point, fieldState) ->
        @drawStroke(point)
        @drawOwnership(point, fieldState.platform.state.owner)
        @drawPlatform(point, fieldState.platform.behaviour.platformType)
        @drawResource(point, fieldState.resource.behaviour.resourceType)
        @setBacklight(point)

    drawPlatform: (point, platform) ->
        g = new Graphics()
        switch platform
            when 1 then g.beginFill("#A6B4B0")
        g.drawPolyStar(point.x, point.y, @size/2, 6, 0, 90)
        @stage.addChild new Shape g

    drawStroke: (point) ->
        g = new Graphics()
        g.beginStroke("#616166")
            .setStrokeStyle(3)
            .drawPolyStar(point.x, point.y, @size, 6, 0, 90)
        @stage.addChild new Shape g

    drawOwnership: (point, owner) ->
        g = new Graphics()
        switch owner
            when 0 then g.beginFill("#000000")
            when 1 then g.beginFill("#274E7D")
            when 2 then g.beginFill("#A60C00")
            else
        g.drawPolyStar(point.x, point.y, @size, 6, 0, 90)
        @stage.addChild new Shape g
    
    drawResource: (point, resource) ->
        g = new Graphics()
        switch resource
            when 1 then g.beginFill("#FFFFFF")
            when 2 then g.beginFill("#000000")
            else
        g.drawCircle(point.x, point.y, 6)
        @stage.addChild new Shape g


    drawChannel: (point, direction) ->
        g = new Graphics()
        point2 = @getDestination(point, direction)
        g.moveTo(point.x, point.y)
            .setStrokeStyle(3)
            .beginStroke("#FFFF00")
            .beginFill("#FFFF00")
            .lineTo(point2.x, point2.y)
        @stage.addChild new Shape g

    drawSignal: (point, direction) ->
        g = new Graphics()
        g.setStrokeStyle(1)
            .beginStroke("#FFFF00")
            .drawCircle(point.x, point.y, 8)
        dest = @getDestination(point, direction)
        shape = new Shape g
        signal = new GSignal(shape, point, dest)
        @signals.addChild signal
        @stage.addChild signal.shape

    setBacklight: (point) ->
        g = new Graphics()
        g.beginStroke("#ED903E")
            .setStrokeStyle(3)
            .drawPolyStar(point.x, point.y, @size, 6, 0, 90)
        overlay = new Shape g
        overlay.visible = false
        overlay.onMouseOver = @mouseOverField
        overlay.onMouseOut = @mouseOutField
        @stage.addChild overlay


#----------------Events-----------------#

    mouseOverField: (event) ->
        event.target.visible = true

    mouseOutField: (event) ->
        event.target.visible = false

    mouseOnClickRadial: (event) ->


#---------------Animation---------------#

    moveSignal: (i, j, channelState) ->
        start = @getPoint(i, j)
        dest = @getDestination(start, channelState.routing)
        @drawSignal(point)


    tick: () ->
        for signal in @signals.children
            if (Math.abs(signal.shape.x) >= Math.abs(signal.closestDest.x) and 
            Math.abs(signal.shape.y) >= Math.abs(signal.closestDest.y))
                signal.shape.visible = false
                # dest = getDestination(new Point(signal.x, signal.y), channelState.routing)
                # signal.setRouting(dest)
            else
                signal.shape.x += signal.tickSizeX
                signal.shape.y += signal.tickSizeY
            @stage.update()



#---------------Interface---------------#

    createPlatfrom: (y, x, fieldState) ->
        point = @getPoint(x, y)
        @drawOwnership(point, fieldState.platform.state.owner)
        @drawPlatform(point, fieldState.platform.behaviour.platformType)
        @stage.update()

    createChannel: (y, x, direction) -> 
        point = @getPoint(x, y)
        @drawOwnership(point, channelState.platform.state.owner)
        @drawChannel(point, direction)
        @stage.update()

    createResource: (y, x, fieldState) ->
        point = @getPoint(x, y)
        @drawResource(point, fieldState.resource.behaviuor.resourceType)
        @stage.update()

    createSignal: (y, x, direction) ->
        point = @getPoint(x, y)
        @drawSignal(point, direction)
        @stage.update()

    drawState: (boardState) ->
        @stage.removeAllChildren()
        for j in [0 ... (2*@diffRows + 1)]
            for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
                point = @getPoint(i, j)
                @drawHex(point, boardState.fields[j][i])
                for k in [0 .. 5]
                    if boardState.channels[j][i][k].state?
                        @drawChannel(point, k)
        @stage.update()

#----------------------------------------#

state = {
  channels: [
    [
        [
            {
                state: null
            },
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: {}
            }
        ]
        [
            {
                state: {}
            },
            {
                state: null
            },
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: {}
            }
        ]
    ]
    [
        [
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: null
            }
        ]
        [
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: {}
            }
        ]
        [
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: null
            },
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: {}
            }
        ]
    ]
    [
        [
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: null
            },
            {
                state: {}
            }
        ]
        [
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: {}
            },
            {
                state: null
            },
            {
                state: {}
            },
            {
                state: {}
            }
        ]
    ]
   ]

  fields: [
    [
      {
      platform: 
          {
            behaviour:
              platformType: {}
            state:
              owner: 1
          }
      resource: 
          {
            behaviour:
              resourceType: 1
            state: {}
          }
      },
      {
      platform: 
          {
            behaviour:
              platformType: {}
            state:
              owner: 2
          }
      resource: 
          {
            behaviour:
              resourceType: 2
            state: {}
          }
      }
    ]
    [
     {
      platform: 
          {
            behaviour:
              platformType: 1
            state:
              owner: 1
          }
      resource: 
          {
            behaviour:
              resourceType: {}
            state: {}
          }
      },
      {
      platform: 
          {
            behaviour:
              platformType: {}
            state:
              owner: 1
          }
      resource: 
          {
            behaviour:
              resourceType: {}
            state: {}
          }
      },
      {
      platform: 
          {
            behaviour:
              platformType: {}
            state:
              owner: 1
          }
      resource: 
          {
            behaviour:
              resourceType: {}
            state: {}
          }
      }
    ],
    [
      {
      platform: 
          {
            behaviour:
              platformType: {}
            state:
              owner: 2
          }
      resource: 
          {
            behaviour:
              resourceType: 2
            state: {}
          }
      },
      {
      platform: 
          {
            behaviour:
              platformType: 1
            state:
              owner: 2
          }
      resource: 
          {
            behaviour:
              resourceType: 2
            state: {}
          }
      },
    ]
   ]
  }

$ ->
    canvas = document.getElementById "board"
    if canvas?
        stage = new Stage canvas
        drawer = new BoardDrawer 1, stage, 2, 3
        drawer.drawState(state)
        drawer.createSignal 1, 1, 0
        drawer.createSignal 1, 1, 1
