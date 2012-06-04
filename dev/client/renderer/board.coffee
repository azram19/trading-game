class GSignal
    tickSizeX: 0
    tickSizeY: 0
    div: 48
    closestDest: {}
    index: 0

    constructor: (@shape, @source, dest) ->
        @setNextTarget(source, dest)

    setTickSizeX: (t) ->
        @tickSizeX = t
    
    getTickSizeX: () ->
        @tickSizeX
    
    setTickSizeY: (t) ->
        @tickSizeY = t
    
    getTickSizeY: () ->
        @tickSizeY

    hasNext: () ->
        @index < @directions.length

    getNext: () ->
        @index++
        @directions[@index]

    setNextTarget: (source, dest) ->
        @closestDest = new Point(dest.x - source.x, dest.y - source.y)
        @setRouting()

    setRouting: () ->
        @setTickSizeX(@closestDest.x/@div)
        @setTickSizeY(@closestDest.y/@div)

class Drawer
    margin: 100
    size: 30
    circleRadius: 8
    horIncrement: 0
    verIncrement: 0
    diffRows: 0
    signals: {}
    basePoint1: {}
    basePoint2: {}
    fpsLabel: {}

    constructor: (@id, @stage, @minRow, @maxRow) ->
        @horIncrement = Math.ceil Math.sqrt(3)*@size/2
        @verIncrement = Math.ceil 3*@size/2
        @diffRows = @maxRow - @minRow

        @stage.enableMouseOver()
        @stage.snapToPixelEnabled = true
        @signals = new Container

        @fpsLabel = new Text("-- fps","bold 18px Arial","#FFF");
        @stage.addChild(@fpsLabel);
        @fpsLabel.x = 10;
        @fpsLabel.y = 20;

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
        console.log fieldState
        if fieldState.platform.type?
            console.log "owner"
            @drawOwnership(point, fieldState.platform.state.owner)
        if fieldState.platform.type?
            console.log "platform"
            @drawPlatform(point, fieldState.platform.type())
        if fieldState.resource.behaviour?
            console.log "resource"
            @drawResource(point, fieldState.resource.type())
        @setBacklight(point)

    drawPlatform: (point, type) ->
        g = new Graphics()
        console.log platform
        switch Types.Platforms[type]
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
        console.log owner
        switch owner
            when 0 then g.beginFill("#000000")
            when 1 then g.beginFill("#274E7D")
            when 2 then g.beginFill("#A60C00")
            else
        g.drawPolyStar(point.x, point.y, @size, 6, 0, 90)
        @stage.addChild new Shape g
    
    drawResource: (point, resource) ->
        g = new Graphics()
        console.log resource
        switch Types.Resources[resource]
            when Types.Resources.Metal then g.beginFill("#FFFFFF")
            when Types.Resources.Tritium then g.beginFill("#FFFF00")
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
            .drawCircle(0, 0, @circleRadius)
        dest = @getDestination(point, direction)
        shape = new Shape g
        shape.x = point.x
        shape.y = point.y
        signal = new GSignal(shape, point, dest)
        @signals.addChild signal
        @stage.addChild signal.shape
        @stage.update()
        shape.snapToPixel = true
        shape.cache(-@circleRadius-1, -@circleRadius-1, (@circleRadius+1)*2, (@circleRadius+1)*2)
        #@toogleCache(true)


    setBacklight: (point) ->
        g = new Graphics()
        g.beginFill("#FFFF00")
            .drawPolyStar(point.x, point.y, @size, 6, 0, 90)
        overlay = new Shape g
        overlay.alpha = 0.5
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

    getDistance: (x, y) ->
        Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2))

    toogleCache: (status) ->
        l = @stage.getNumChildren() - 1
        for i in [0..l]
            shape = @stage.getChildAt i
            if status
                shape.cache(-@circleRadius, -@circleRadius, @circleRadius*2, @circleRadius*2)
            else
                shape.uncache()

    tick: () ->
        for signal in @signals.children
            if signal.shape.isVisible()
                if @getDistance(signal.shape.x - signal.source.x, signal.shape.y - signal.source.y) >= 2*@horIncrement
                    signal.tickSizeX = -signal.tickSizeX
                    signal.tickSizeY = -signal.tickSizeY
                signal.shape.x += signal.tickSizeX
                signal.shape.y += signal.tickSizeY
        @fpsLabel.text = Math.round(Ticker.getMeasuredFPS())+" fps";
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
                    if boardState.channels?[j]?[i]?[k]?.state?
                        @drawChannel(point, k)
        @stage.update()

class ChannelDrawer
    constructor: (@id, @stage, @minRow, @maxRow) ->
        super @id, @stage, @minRow, @maxRow

class SignalsDrawer
    constructor: (@id, @stage, @minRow, @maxRow) ->
        super @id, @stage, @minRow, @maxRow

class BoardDrawer
    constructor: (@id, @stage, @minRow, @maxRow) ->
        super @id, @stage, @minRow, @maxRow

class BackgroundDrawer
    constructor: (@stage) ->
        img = new Image
        img.src = "address"
        img.onload = @setBg

    setBg: (event) =>
        bg = new Bitmap event.target
        @stage.addChild bg
        @stage.update()

#----------------------------------------#

player = ObjectFactory.build Types.Entities.Player
manager = new GameManager [player], [[2,2]], 8, 15
state = manager.map
console.log state
###
state = {
  channels: [
    [
        [
            {
                state: null
            },
            {
                state: null
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
                state: null
            }
        ]
        [
            {
                state: null
            },
            {
                state: null
            },
            {
                state: null
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
    ]
    [
        [
            {
                state: null
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
                state: null
            },
            {
                state: null
            }
        ]
        [
            {
                state: null
            },
            {
                state: null
            },
            {
                state: null
            },
            {
                state: null
            },
            {
                state: null
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
                state: null
            },
            {
                state: null
            },
            {
                state: null
            },
            {
                state: {}
            },
            {
                state: null
            }
        ]
    ]
    [
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
                state: null
            },
            {
                state: null
            },
            {
                state: null
            }
        ]
        [
            {
                state: null
            },
            {
                state: {}
            },
            {
                state: null
            },
            {
                state: null
            },
            {
                state: null
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
###
$ ->
    canvasBoard = document.getElementById "board"
    canvasBackground = document.getElementById "background"
    canvasSignals = document.getElementById "signals"
    canvasChannels = document.getElementById "channels"
    ###
    if canvasBackground?
        stageBackground = new Stage canvasBackground
        bgDrawer = new BackgroundDrawer stageBackground
    ###
    if canvasBoard?
        stageBoard = new Stage canvasBoard
        boardDrawer = new Drawer 1, stageBoard, 8, 15
        boardDrawer.drawState(state)
    ###
    if canvasChannels?
        stageChannels = new Stage canvasChannels
        channelDrawer = new Drawer 2, stageChannels, 2, 3   
    ###
    ###
    if canvasSignals?
        stageSignals = new Stage canvasSignals
        signalsDrawer = new Drawer 3, stageSignals, 8, 15
        Ticker.addListener signalsDrawer
        Ticker.useRAF = true
        Ticker.setFPS 60
        for y in [0..8]
            for x in [0..4]
                signalsDrawer.createSignal y, x, 0
                signalsDrawer.createSignal y, x, 1
    ###
