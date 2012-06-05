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
    horIncrement: 0
    verIncrement: 0
    diffRows: 0

    constructor: (@stage, @minRow, @maxRow) ->
        @horIncrement = Math.ceil Math.sqrt(3)*@size/2
        @verIncrement = Math.ceil 3*@size/2
        @diffRows = @maxRow - @minRow

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

class ChannelsDrawer extends Drawer
    constructor: (@stage, @minRow, @maxRow) ->
        super @stage, @minRow, @maxRow

    drawChannel: (point, destination) ->
        g = new Graphics()
        g.moveTo(point.x, point.y)
            .setStrokeStyle(3)
            .beginStroke("#FFFF00")
            .beginFill("#FFFF00")
            .lineTo(destination.x, destination.y)
        @stage.addChild new Shape g

    createChannel: (y, x, direction, channelState) ->
        point = @getPoint(x, y)
        destination = @getDestination(point, direction)
        @drawChannel(point, destination)
        @stage.update()

    drawState: (boardState) ->
        @stage.removeAllChildren()
        for j in [0 ... (2*@diffRows + 1)]
            for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
                point = @getPoint(i, j)
                for k in [0 .. 5]
                    if boardState.getChannel(j, i, k)?.state?
                        @drawChannel(point, k)
        @stage.update()

class SignalsDrawer extends Drawer
    fpsLabel: {}
    signals: {}
    signalRadius: 8

    constructor: (@stage, @minRow, @maxRow) ->
        super @stage, @minRow, @maxRow

        @stage.snapToPixelEnabled = true
        @signals = new Container

        Ticker.addListener this
        Ticker.useRAF = true
        Ticker.setFPS 60

        @fpsLabel = new Text("-- fps","bold 18px Arial","#FFF");
        @stage.addChild(@fpsLabel);
        @fpsLabel.x = 10;
        @fpsLabel.y = 20;

    drawSignal: (point, destination) ->
        g = new Graphics()
        g.setStrokeStyle(1)
            .beginStroke("#FFFF00")
            .drawCircle(0, 0, @signalRadius)
        shape = new Shape g
        shape.x = point.x
        shape.y = point.y
        signal = new GSignal(shape, point, destination)
        @signals.addChild signal
        @stage.addChild signal.shape
        @stage.update()
        shape.snapToPixel = true
        shape.cache(-@signalRadius-1, -@signalRadius-1, (@signalRadius+1)*2, (@signalRadius+1)*2)
        #@toogleCache(true)

    createSignal: (y, x, direction) ->
        point = @getPoint(x, y)
        destination = @getDestination(point, direction)
        @drawSignal(point, destination)
        @stage.update()

    getDistance: (x, y) ->
        Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2))

    toogleCache: (status) ->
        l = @stage.getNumChildren() - 1
        for i in [0..l]
            shape = @stage.getChildAt i
            if status
                shape.cache(-@signalRadius-1, -@signalRadius-1, (@signalRadius+1)*2, (@signalRadius+1)*2)
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

class ResourcesDrawer extends Drawer
    constructor: (@stage, @minRow, @maxRow) ->
        super @stage, @minRow, @maxRow

    drawResource: (point, resource) ->
        g = new Graphics()
        switch resource
            when Types.Resources.Metal then g.beginFill("#FFFFFF")
            when Types.Resources.Tritium then g.beginFill("#FFFF00")
            else
        g.drawCircle(point.x, point.y, 6)
        @stage.addChild new Shape g

    createResource: (y, x, fieldState) ->
        point = @getPoint(x, y)
        @drawResource(point, fieldState.resource.type())
        @stage.update()

    drawState: (boardState) ->
        @stage.removeAllChildren()
        for j in [0 ... (2*@diffRows + 1)]
            for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
                fieldState = boardState.getField(j, i)
                if fieldState.resource.behaviour?
                    @drawResource(point, fieldState.resource.type())
        @stage.update()

class PlatformsDrawer extends Drawer
    constructor: (@stage, @minRow, @maxRow) ->
        super @stage, @minRow, @maxRow

    drawPlatform: (point, type) ->
        g = new Graphics()
        switch type
            when Types.Platforms.HQ then g.beginFill("#A6B4B0")
        g.drawPolyStar(point.x, point.y, @size/2, 6, 0, 90)
        @stage.addChild new Shape g

    createPlatfrom: (y, x, fieldState) ->
        point = @getPoint(x, y)
        @drawPlatform(point, fieldState.platform.type())
        @stage.update()

    drawState: (boardState) ->
        @stage.removeAllChildren()
        for j in [0 ... (2*@diffRows + 1)]
            for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
                fieldState = boardState.getField(j, i)
                if fieldState.platform.type?
                    point = @getPoint(i, j)
                    @drawPlatform(point, fieldState.platform.type())
        @stage.update()

class OwnershipDrawer extends Drawer
    constructor: (@stage, @minRow, @maxRow) ->
        super @stage, @minRow, @maxRow

    drawOwnership: (point, owner) ->
        g = new Graphics()
        switch owner.id
            when 0 then g.beginFill("#274E7D")
            when 1 then g.beginFill("#A60C00")
            else g.beginFill("#000000")
        g.drawPolyStar(point.x, point.y, @size, 6, 0, 90)
        @stage.addChild new Shape g

    createOwnership: (y, x, fieldState) ->
        point = @getPoint(x, y)
        @drawOwnership(point, fieldState.platform.state.owner)
        @stage.update()

    drawState: (boardState) ->
        @stage.removeAllChildren()
        for j in [0 ... (2*@diffRows + 1)]
            for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
                fieldState = boardState.getField(j, i)
                if fieldState.platform.type?
                    point = @getPoint(i, j)
                    @drawOwnership(point, fieldState.platform.state.owner)
        @stage.update()

class GridDrawer extends Drawer
    constructor: (@stage, @minRow, @maxRow) ->
        super @stage, @minRow, @maxRow

    drawStroke: (point) ->
        g = new Graphics()
        g.beginStroke("#616166")
            .setStrokeStyle(3)
            .drawPolyStar(point.x, point.y, @size, 6, 0, 90)
        @stage.addChild new Shape g

    createStroke: (y, x) ->
        point = @getPoint(x, y)
        @drawStroke(point)
        @stage.update()

    drawState: () ->
        @stage.removeAllChildren()
        for j in [0 ... (2*@diffRows + 1)]
            for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
                point = @getPoint(i, j)
                @drawStroke(point)
        @stage.update()

class OverlayDrawer extends Drawer
    constructor: (@stage, @minRow, @maxRow) ->
        super @stage, @minRow, @maxRow
        @stage.enableMouseOver(20)

    drawOverlay: (point) ->
        g = new Graphics()
        g.beginFill("#FFFF00")
            .drawPolyStar(point.x, point.y, @size, 6, 0, 90)
        overlay = new Shape g
        overlay.alpha = 0.01
        @stage.addChild overlay
        overlay.onMouseOver = @mouseOverField
        overlay.onMouseOut = @mouseOutField

    createOverlay: (y, x) ->
        point = @getPoint(x, y)
        @drawOverlay point
        @stage.update()

    drawState: () ->
        @stage.removeAllChildren()
        for j in [0 ... (2*@diffRows + 1)]
            for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
                point = @getPoint(i, j)
                @drawOverlay(point)
        @stage.update()

    mouseOverField: (event) =>
        console.log "gey"
        event.target.alpha = 0.2
        @stage.update()

    mouseOutField: (event) =>
        event.target.alpha = 0.01
        @stage.update()

class BackgroundDrawer
    constructor: (@stage) ->
        img = new Image
        #img.src = "address"
        #img.onload = @setBg

    setBg: (event) =>
        bg = new Bitmap event.target
        @stage.addChild bg
        @stage.update()

class Renderer
    drawers: []
    #---Drawers---#
    backgroundDR: {}
    ownershipDR: {}
    resourcesDR: {}
    gridDR: {}
    platformsDR: {}
    channelsDR: {}
    overlayDR: {}
    signalsDR: {}
    UIDR: {}

    stages: []
    #---Stages---#
    backgroundST: {}
    ownershipST: {}
    resourcesST: {}
    gridST: {}
    platformsST: {}
    channelsST: {}
    overlayST: {}
    signalsST: {}
    UIST: {}

    diffRows: 0

    constructor: (@minRow, @maxRow) ->
        canvasBackground = document.getElementById "background"
        canvasOwnership = document.getElementById "ownership"
        canvasResources = document.getElementById "resources"
        canvasGrid = document.getElementById "grid"
        canvasPlatforms = document.getElementById "platforms"
        canvasChannels = document.getElementById "channels"
        canvasOverlay = document.getElementById "overlay"
        canvasSignals = document.getElementById "signals"
        canvasUI = document.getElementById "UI"

        if canvasBackground?
            @backgroundST = new Stage canvasBackground
            @backgroundDR = new BackgroundDrawer @backgroundST
            @addSTDR(@backgroundST, @backgroundDR)
        if canvasOwnership?
            @ownershipST = new Stage canvasOwnership
            @ownershipDR = new OwnershipDrawer @ownershipST, @minRow, @maxRow
            @addSTDR(@ownershipST, @ownershipDR)
        if canvasResources?
            @resourcesST = new Stage canvasResources
            @resourcesDR = new ResourcesDrawer @resourcesST, @minRow, @maxRow
            @addSTDR(@resourcesST, @resourcesDR)
        if canvasGrid?
            @gridST = new Stage canvasGrid
            @gridDR = new GridDrawer @gridST, @minRow, @maxRow
            @addSTDR(@gridST, @gridDR)
        if canvasPlatforms?
            @platformsST = new Stage canvasPlatforms
            @platformsDR = new PlatformsDrawer @platformsST, @minRow, @maxRow
            @addSTDR(@platformsST, @platformsDR)
        if canvasChannels?
            @channelsST = new Stage canvasChannels
            @channelsDR = new ChannelsDrawer @channelsST, @minRow, @maxRow
            @addSTDR(@channelsST, @channelsDR)
        if canvasOverlay?
            @overlayST = new Stage canvasOverlay
            @overlayDR = new OverlayDrawer @overlayST, @minRow, @maxRow
            @addSTDR(@overlayST, @overlayDR)
        if canvasSignals?
            @signalsST = new Stage canvasSignals
            @signalsDR = new SignalsDrawer @signalsST, @minRow, @maxRow
            @addSTDR(@signalsST, @signalsDR)
        ###
        if canvasUI?
            @UIST = new Stage canvasUI
            @UIDR = new UIDrawer @UIST, @minRow, @maxRow
            @addSTDR(@UIST, @UIDR)
        ###
        @diffRows = @maxRow - @minRow

    addSTDR: (stage, drawer) ->
        @stages.push stage
        @drawers.push drawer

    setupOverlay: (y, x) ->
        @overlayDR.createOverlay(y, x)

    moveSignal: (y, x, direction) ->
        @signalsDR.createSignal(y, x, direction)

    buildChannel: (y, x, direction, channelState) ->
        @channelsDR.createChannel(y, x, direction, channelState)

    buildPlatform: (y, x, fieldState) ->
        @boardDR.createPlatfrom(y, x, fieldState)

    buildResource: (y, x, fieldState) ->
        @boardDR.createResource(y, x, fieldState)

    captureChannel: (y, x, direction, channelState) ->

    capturePlatform: (y, x, fieldState) ->

    drawHex: (point, fieldState) ->
        if fieldState.platform.type?
            @ownershipDR.drawOwnership(point, fieldState.platform.state.owner)
        if fieldState.resource.behaviour?
            @resourcesDR.drawResource(point, fieldState.resource.type())
        if fieldState.platform.type?
            @platformsDR.drawPlatform(point, fieldState.platform.type())
        @gridDR.drawStroke(point)
        @overlayDR.drawOverlay(point)

    clearAll: () ->
        for stage in @stages
            stage.removeAllChildren()

    updateAll: () ->
        for stage in @stages
            stage.update()

    setupBoard: (boardState) ->
        @clearAll()
        for j in [0 ... (2*@diffRows + 1)]
            for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
                point = @ownershipDR.getPoint(i, j)
                @drawHex(point, boardState.fields[j][i])
                for k in [0 .. 5]
                    if boardState.getChannel(j, i, k)?.state?
                        @channelsDR.drawChannel(point, k)
        @updateAll()

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
    if $('#radial').length <= 0
        renderer = new Renderer 8, 15
        renderer.setupBoard(state)
        for y in [0..4]
                for x in [0..4]
                    renderer.moveSignal y, x, 0
        renderer.buildChannel 2, 2, 3, channelStat
        renderer.buildChannel 3, 3, 3, channelStat
        renderer.buildChannel 4, 4, 5, channelStat
