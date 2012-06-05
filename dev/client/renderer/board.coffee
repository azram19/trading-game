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
    fpsLabel: {}
    players: []

    constructor: (@id, @stage, @minRow, @maxRow) ->
        @horIncrement = Math.ceil Math.sqrt(3)*@size/2
        @verIncrement = Math.ceil 3*@size/2
        @diffRows = @maxRow - @minRow

        @stage.enableMouseOver(20)
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
        if fieldState.platform.type?
            @drawOwnership(point, fieldState.platform.state.owner)
        if fieldState.resource.behaviour?
            @drawResource(point, fieldState.resource.type())
        if fieldState.platform.type?
            @drawPlatform(point, fieldState.platform.type())
        #@drawOverlay(point)
        @drawStroke(point)

    drawPlatform: (point, type) ->
        g = new Graphics()
        switch type
            when Types.Platforms.HQ then g.beginFill("#A6B4B0")
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
        switch owner.id
            when 0 then g.beginFill("#274E7D")
            when 1 then g.beginFill("#A60C00")
            else g.beginFill("#000000")
        g.drawPolyStar(point.x, point.y, @size, 6, 0, 90)
        @stage.addChild new Shape g
        @drawStroke point
    
    drawResource: (point, resource) ->
        g = new Graphics()
        switch resource
            when Types.Resources.Metal then g.beginFill("#FFFFFF")
            when Types.Resources.Tritium then g.beginFill("#FFFF00")
            else
        g.drawCircle(point.x, point.y, 6)
        @stage.addChild new Shape g

    drawChannel: (point, destination) ->
        g = new Graphics()
        g.moveTo(point.x, point.y)
            .setStrokeStyle(3)
            .beginStroke("#FFFF00")
            .beginFill("#FFFF00")
            .lineTo(destination.x, destination.y)
        @stage.addChild new Shape g

    drawSignal: (point, destination) ->
        g = new Graphics()
        g.setStrokeStyle(1)
            .beginStroke("#FFFF00")
            .drawCircle(0, 0, @circleRadius)
        shape = new Shape g
        shape.x = point.x
        shape.y = point.y
        signal = new GSignal(shape, point, destination)
        @signals.addChild signal
        @stage.addChild signal.shape
        @stage.update()
        shape.snapToPixel = true
        shape.cache(-@circleRadius-1, -@circleRadius-1, (@circleRadius+1)*2, (@circleRadius+1)*2)
        #@toogleCache(true)


    drawOverlay: (point) ->
        g = new Graphics()
        g.beginFill("#FFFF00")
            .drawPolyStar(point.x, point.y, @size, 6, 0, 90)
        overlay = new Shape g
        overlay.alpha = 0.01
        @stage.addChild overlay
        overlay.onMouseOver = @mouseOverField
        overlay.onMouseOut = @mouseOutField

#----------------Events-----------------#

    mouseOverField: (event) =>
        console.log "gey"
        event.target.alpha = 0.2
        @stage.update()

    mouseOutField: (event) =>
        event.target.alpha = 0.01
        @stage.update()

    mouseOnClickRadial: (event) =>

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
        @drawPlatform(point, fieldState.platform.type())
        @stage.update()

    createChannel: (y, x, direction, channelState) -> 
        point = @getPoint(x, y)
        destination = @getDestination(point, direction)
        @drawOwnership(destination, channelState.platform.state.owner)
        @drawChannel(point, destination)
        @stage.update()

    createResource: (y, x, fieldState) ->
        point = @getPoint(x, y)
        @drawResource(point, fieldState.resource.type())
        @stage.update()

    createSignal: (y, x, direction) ->
        point = @getPoint(x, y)
        destination = @getDestination(point, direction)
        @drawSignal(point, destination)
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

    setBacklight: () ->
        @stage.removeAllChildren()
        for j in [0 ... (2*@diffRows + 1)]
            for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
                point = @getPoint(i, j)
                @drawOverlay(point)
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

channelStat =
    state: {}
    platform: {
        behaviour:
            platformType: {}
        state:
            owner:
                id: 0
        }

$ ->
    canvasBackground = document.getElementById "background"
    canvasBoard = document.getElementById "board"
    canvasChannels = document.getElementById "channels"
    canvasSignals = document.getElementById "signals"
    ###
    if canvasBackground?
        stageBackground = new Stage canvasBackground
        bgDrawer = new BackgroundDrawer stageBackground
    ###
    if canvasBoard?
        stageBoard = new Stage canvasBoard
        boardDrawer = new Drawer 1, stageBoard, 8, 15
        boardDrawer.drawState(state)        
        boardDrawer.createChannel 2, 2, 3, channelStat
        boardDrawer.createChannel 3, 3, 3, channelStat
        boardDrawer.createChannel 4, 4, 5, channelStat
    if canvasChannels?
        stageChannels = new Stage canvasChannels
        channelDrawer = new Drawer 2, stageChannels, 8, 15 
        channelDrawer.setBacklight() 
    if canvasSignals?
        stageSignals = new Stage canvasSignals
        signalsDrawer = new Drawer 3, stageSignals, 8, 15
        Ticker.addListener signalsDrawer
        Ticker.useRAF = true
        Ticker.setFPS 60
        signalsDrawer.createSignal 3, 3, 3
        for y in [0..4]
            for x in [0..4]
                signalsDrawer.createSignal y, x, 0

        

    
