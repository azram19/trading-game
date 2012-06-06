class Drawer
    margin: 100
    size: 30
    diffRows: 0
    horIncrement: 0
    verIncrement: 0
    div: 48
    offsetX: []
    offsetY: []
    ticksX: []
    ticksY: []

    constructor: (@stage, @minRow, @maxRow) ->
        @horIncrement = Math.ceil Math.sqrt(3)*@size/2
        @verIncrement = Math.ceil 3*@size/2
        @diffRows = @maxRow - @minRow
        @setupOffsets()
        @setupTicks()

    setupOffsets: () ->
        @offsetX = [-@horIncrement, @horIncrement, 2*@horIncrement, @horIncrement, -@horIncrement, -2*@horIncrement]
        @offsetY = [-@verIncrement, -@verIncrement, 0, @verIncrement, @verIncrement, 0]

    setupTicks: () ->
        @ticksX = [-@horIncrement / @div, @horIncrement / @div, 2*@horIncrement / @div, @horIncrement / @div, -@horIncrement / @div, -2*@horIncrement / @div]
        @ticksY = [-@verIncrement / @div, -@verIncrement / @div, 0, @verIncrement / @div, @verIncrement / @div, 0]

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
        p = new Point(point.x + @offsetX[dir], point.y + @offsetY[dir])

    getTicks: (dir) ->
        p = new Point(@ticksX[dir], @ticksY[dir])

    getCoords: (x, y) ->
        offset = @margin + Math.abs(@diffRows-j)*@horIncrement
        i = (x - offset) / 2*@horIncrement
        j = (y - @margin) / @verIncrement
        new Point(i,j)

window.Drawer = Drawer

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
        destination

    drawState: (boardState) ->
        @stage.removeAllChildren()
        for j in [0 ... (2*@diffRows + 1)]
            for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
                point = @getPoint(i, j)
                for k in [0 .. 5]
                    if boardState.getChannel(j, i, k)?.state?
                        @drawChannel(point, k)
        @stage.update()

class OffSignals
    signalRadius: 8
    signalCount: 50
    incoming: 0
    out: 0

    constructor: (@stage, @distance, @div) ->
        @stage.snapToPixelEnabled = true
        @setupSignalTable()

    getSignal: () ->
        shape = @stage.getChildAt @out
        @stage.removeChildAt @out
        @out = (@out + 1) % @signalCount
        shape

    returnSignal: (signal) ->
        @stage.addChildAt signal, @incoming
        @incoming = (@incoming + 1) % @signalCount

    setupSignalTable: () ->
        for i in [0..@signalCount]
            @drawSignal()
        @toogleCache(true)
        @stage.update()

    doubleSignalTable: () ->
        @signalCount = 2*@signalCount
        @setupSignalTable()

    drawSignal: () ->
        g = new Graphics()
        g.setStrokeStyle(1)
            .beginStroke("#FFFF00")
            .drawCircle(0, 0, @signalRadius)
        shape = new Shape g
        shape.snapToPixel = true
        shape.visible = false
        shape.isSignal = true
        #shape.cache(-@signalRadius-1, -@signalRadius-1, (@signalRadius+1)*2, (@signalRadius+1)*2)
        @stage.addChild shape
        
    toogleCache: (status) ->
        length = @stage.getNumChildren() - 1
        for i in [0..length]
            shape = @stage.getChildAt i
            if status
                shape.cache(-@signalRadius-1, -@signalRadius-1, (@signalRadius+1)*2, (@signalRadius+1)*2)
            else
                shape.uncache()

class SignalsDrawer extends Drawer
    fpsLabel: {}
    offSignals: {}
    signalRadius: 8
    signalCount: 50

    constructor: (@stage, @minRow, @maxRow, @offStage) ->
        super @stage, @minRow, @maxRow
        @distance = 2*@horIncrement
        @offSignals = new OffSignals @offStage

        Ticker.addListener this
        Ticker.useRAF = true
        Ticker.setFPS 60
        @setupFPS()

    setupFPS: () ->
        @fpsLabel = new Text "-- fps", "bold 18px Arial", "#FFF"
        @stage.addChild @fpsLabel
        @fpsLabel.x = 10
        @fpsLabel.y = 20
        @fpsLabel.isSignal = false

    drawSignal: (point, dir) ->
        signal = @getSignal()
        if signal is null
            signal = @offSignals.getSignal()
            @stage.addChild signal
        signal.source = new Point(point.x, point.y)
        signal.x = point.x
        signal.y = point.y
        signal.tickSizeX = @ticksX[dir]
        signal.tickSizeY = @ticksY[dir]
        signal.visible = true
        signal.k = 0
        @stage.update()

    getSignal: () ->
        for sig in @stage.children
            if sig.isSignal and not sig.isVisible
                return sig
        null

    createSignal: (y, x, direction) ->
        point = @getPoint(x, y)
        @drawSignal(point, direction)
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
        for signal in @stage.children
            if signal.isSignal and signal.isVisible
                if @getDistance(signal.k * signal.tickSizeX, signal.k * signal.tickSizeY) >= 2*@horIncrement
                    signal.visible = false
                else   
                    signal.x += signal.tickSizeX
                    signal.y += signal.tickSizeY
                    signal.k += 1
        @fpsLabel.text = Math.round(Ticker.getMeasuredFPS())+" fps"
        #@stage.children = _.reject @stage.children, @filterSignals
        @stage.update()

    filterSignals: (signal) => 
            if signal.mark
                @offSignals.returnSignal signal
                true
            else 
                false
        
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
        Ticker.addListener this
        Ticker.useRAF = true
        Ticker.setFPS 60

    drawOverlay: (point) ->
        g = new Graphics()
        g.beginFill("#FFFF00")
            .drawPolyStar(point.x, point.y, @size, 6, 0, 90)
        overlay = new Shape g
        overlay.alpha = 0.01
        @stage.addChild overlay
        ###
        boundaries =
            x: point.x - @horIncrement
            y: point.y - @size
            width: 2*@horIncrement
            height: 2*@size
        ###
        #Mouse.register {target: overlay, boundaries: boundaries}, @mouseOutField, ['mouseout']
        #Mouse.register {target: overlay, boundaries: boundaries}, @mouseOverField, ['mousein']

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
        #if event.target.hitTest(x, y)
        event.target.alpha = 0.2
        @update = true

    mouseOutField: (event) =>
        #if not event.target.hitTest(x, y)
        event.target.alpha = 0.01
        @update = true
        ###
        else
            event.target.alpha = 0.2
        @stage.update()
        ###

    fieldClick: (event) =>
        coords = getCoords(event.stageX, event.stageY)

    tick: () ->
        if(@update)
            @update = false
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
        canvasOff = document.getElementById "off"

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
            window.Mouse = new MouseClass canvasOverlay, 1280, 800
        
        if canvasSignals?
            @signalsST = new Stage canvasSignals
            @offStage = new Stage canvasOff
            @signalsDR = new SignalsDrawer @signalsST, @minRow, @maxRow, @offStage
            @addSTDR(@signalsST, @signalsDR)
        ###
        if canvasUI?
            @UIST = new Stage canvasUI
            @UIDR = new OverlayDrawer @UIST, @minRow, @maxRow
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
        dest = @channelsDR.createChannel(y, x, direction, channelState) 
        @ownershipDR.drawOwnership(dest, channelState.state.owner)
        @ownershipST.update()

    buildPlatform: (y, x, fieldState) ->
        @boardDR.createPlatfrom(y, x, fieldState)

    buildResource: (y, x, fieldState) ->
        @boardDR.createResource(y, x, fieldState)

    captureChannel: (y, x, direction, channelState) ->
        point = @ownershipDR.getPoint(x, y)
        dest = @ownershipDR.getDestination(point, direction)
        @ownershipDR.drawOwnership(dest, channelState.state.owner)

    capturePlatform: (y, x, fieldState) ->
        @point = @ownershipDR.getPoint(x, y)
        @ownershipDR.drawOwnership(dest, channelState.state.owner)

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
        @signalsDR.setupFPS()
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
    state: {
        owner:
            id: 0
    }
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
                    renderer.moveSignal y, x, 2
        renderer.buildChannel 2, 2, 3, channelStat
        renderer.buildChannel 3, 3, 3, channelStat
        renderer.buildChannel 4, 4, 5, channelStat

