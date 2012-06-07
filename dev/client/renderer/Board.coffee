class Drawer
    margin: 100
    size: 30
    div: 60

    # horIncrement is a horizontal distance between centers of two hexes divided by two
    # verIncrement is a vertical distance between centers of two hexes
    constructor: (@stage, @minRow, @maxRow) ->
        @horIncrement = Math.ceil Math.sqrt(3)*@size/2
        @verIncrement = Math.ceil 3*@size/2
        @diffRows = @maxRow - @minRow
        @distance = 2*@horIncrement
        @ticksX = []
        @ticksY = []
        @offsetX = []
        @offsetY = []
        @setupOffsets()
        @setupTicks()

    # Setups table of offsets according to direction
    setupOffsets: () ->
        @offsetX = [-@horIncrement, @horIncrement, 2*@horIncrement, @horIncrement, -@horIncrement, -2*@horIncrement]
        @offsetY = [-@verIncrement, -@verIncrement, 0, @verIncrement, @verIncrement, 0]

    # Setups table of tick sizes according to the direction
    setupTicks: () ->
        for i in [0..5]
            @ticksX[i] = @offsetX[i]/@div
            @ticksY[i] = @offsetY[i]/@div
        true

    # Sets the size of each field (distance between the center and a corner of a hex)
    setSize: (size) ->
        @size = size

    # Sets the margin: distance between left border of the screen and center of the leftmost
    # hex in the middle row of the board and the distance between the top border of the
    # screen and center of a hex in the top row of the board
    setMargin: (margin) ->
        @margin = margin

    # Arguments: coordinates x, y on the board
    # Returns canvas coordinates in pixels
    getPoint: (x, y) ->
        offset = @margin + Math.abs(@diffRows - y)*@horIncrement
        new Point(offset + 2*x*@horIncrement, @margin + y*@verIncrement)

    # Arguments: point with canvas coordinates and direction (0..5)
    # Returns canvas coordinates of destination point in particular direction
    getDestination: (point, direction) ->
        new Point(point.x + @offsetX[direction], point.y + @offsetY[direction])

    # Arguments: point with canvas coordinates (which is a center of particular hex)
    # Returns board coordinates of particular point
    getCoords: (point) ->
        y = (point.y - @margin) / @verIncrement
        offset = @margin + Math.abs(@diffRows-y)*@horIncrement
        x = (point.x - offset) / (2*@horIncrement)
        new Point Math.round(x), Math.round(y)

    # Arguments: direction
    # Returns point with tick sizes for particular direction
    getTicks: (direction) ->
        p = new Point(@ticksX[direction], @ticksY[direction])

    # Calculates hypotenuse of a triangle with side lengths x, y
    getDistance: (x, y) ->
        Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2))

class BoardDrawer
    constructor: (@ownershipST, @resourcesST, @gridST, @platformsST, @channelsST, @overlayST, @helper) ->
        @uiHandler = new UIHandler @overlayST, @helper

    buildPlatform: (x, y, type) ->
        point = @helper.getPoint(x, y)
        @drawPlatform(point, type)
        @platformsST.update()

    capturePlatform: (x, y, owner) ->
        point = @helper.getPoint x, y
        @drawOwnership point, owner
        @ownershipST.update()

    buildChannel: (x, y, direction, owner) ->
        point = @helper.getPoint(x, y)
        destination = @helper.getDestination(point, direction)
        @drawChannel(point, direction)
        @drawOwnership(destination, owner)
        @channelsST.update()
        @ownershipST.update()

    captureChannel: (x, y, direction, owner) ->
        point = @helper.getPoint(x, y)
        destination = @helper.getDestination(point, direction)
        @drawOwnership(destination, owner)
        @ownershipST.update()

    drawOwnership: (point, owner) ->
        g = new Graphics()
        # FIXME Ids can be very, very random
        switch owner.id
            when 0 then g.beginFill("#274E7D")
            when 1 then g.beginFill("#900020")
        g.drawPolyStar(point.x, point.y, @helper.size, 6, 0, 90)
        @ownershipST.addChild new Shape g

    drawPlatform: (point, type) ->
        g = new Graphics()
        switch type
            when Types.Platforms.Normal then g.beginFill("#A6B4B0")
            when Types.Platforms.HQ then g.beginFill("#C5B356")
        g.drawPolyStar(point.x, point.y, 2*@helper.size/3, 6, 0, 90)
        @platformsST.addChild new Shape g

    drawResource: (point, resource) ->
        g = new Graphics()
        switch resource
            when Types.Resources.Metal then g.beginFill("#FFFFFF")
            when Types.Resources.Tritium then g.beginFill("#FFFF00")
        g.drawCircle(point.x, point.y, 6)
        @resourcesST.addChild new Shape g

    drawChannel: (point, direction) ->
        destination = @helper.getDestination(point, direction)
        g = new Graphics()
        g.moveTo(point.x, point.y)
            .setStrokeStyle(3)
            .beginStroke("#FFFF00")
            .beginFill("#FFFF00")
            .lineTo(destination.x, destination.y)
        @channelsST.addChild new Shape g

    drawStroke: (point) ->
        g = new Graphics()
        g.beginStroke("#616166")
            .setStrokeStyle(3)
            .drawPolyStar(point.x, point.y, @helper.size, 6, 0, 90)
        @gridST.addChild new Shape g

    drawHex: (point, field) ->
        if field.platform.type?
            @drawOwnership point, field.platform.state.owner
        if field.resource.behaviour?
            @drawResource point, field.resource.type()
        if field.platform.type?
            @drawPlatform point, field.platform.type()
        @drawStroke point
        @uiHandler.drawOverlay point

    setupBoard: (boardState) ->
        for j in [0 ... (2*@helper.diffRows + 1)]
            for i in [0 ... @helper.maxRow - Math.abs(@helper.diffRows - j)]
                point = @helper.getPoint(i, j)
                @drawHex(point, boardState.getField(i, j))
                for k in [0 .. 5]
                    if boardState.getChannel(i, j, k)?.state?
                        @drawChannel(point, k)
        true

class UIHandler
    constructor: (@stage, @helper) ->
        @stage.enableMouseOver(20)
        Ticker.addListener this

    drawOverlay: (point) ->
        g = new Graphics()
        g.beginFill("#FFFF00")
            .drawPolyStar(point.x, point.y, @helper.size, 6, 0, 90)
        overlay = new Shape g
        overlay.alpha = 0.01
        @stage.addChild overlay
        overlay.onMouseOver = @mouseOverField
        overlay.onMouseOut = @mouseOutField

    mouseOverField: (event) =>
        event.target.alpha = 0.2
        @update = true

    mouseOutField: (event) =>
        event.target.alpha = 0.01
        @update = true

    tick: () ->
        if(@update)
            @update = false
            @stage.update()

class OffSignals
    signalRadius: 8
    signalCount: 50

    constructor: (@stage) ->
        @stage.snapToPixelEnabled = true

    getSignal: () ->
        signal = @stage.getChildAt 0
        if @stage.removeChildAt 0
            signal
        else
            @addNewSignals()
            @getSignal()

    setupSignalTable: () ->
        for i in [0..@signalCount]
            @drawSignal()
        @toogleCache(true)

    addNewSignals: () ->
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
        @stage.addChild shape

    toogleCache: (status) ->
        length = @stage.getNumChildren() - 1
        for i in [0..length]
            shape = @stage.getChildAt i
            if status
                shape.cache(-@signalRadius-1, -@signalRadius-1, (@signalRadius+1)*2, (@signalRadius+1)*2)
            else
                shape.uncache()
        true

class SignalsDrawer
    signalRadius: 8
    signalCount: 50

    constructor: (@stage, @offStage, @helper) ->
        @offSignals = new OffSignals @offStage
        Ticker.addListener this

    setupFPS: () ->
        @fpsLabel = new Text "-- fps", "bold 18px Arial", "#FFF"
        @stage.addChild @fpsLabel
        @fpsLabel.x = 10
        @fpsLabel.y = 20
        @fpsLabel.isSignal = false

    setupOffSignals: () ->
        @offSignals.setupSignalTable()

    drawSignal: (point, dir) ->
        signal = @getSignal()
        if signal is null
            #console.log "new"
            signal = @offSignals.getSignal()
            @stage.addChild signal
        signal.x = point.x
        signal.y = point.y
        signal.tickSizeX = @helper.ticksX[dir]
        signal.tickSizeY = @helper.ticksY[dir]
        signal.visible = true
        signal.k = 0
        @stage.update()

    getSignal: () ->
        for sig in @stage.children
            if sig.isSignal and not sig.visible
                #console.log "used"
                return sig
        null

    createSignal: (y, x, direction) ->
        point = @helper.getPoint(x, y)
        @drawSignal(point, direction)
        @stage.update()

    tick: () ->
        for signal in @stage.children
            if signal.isSignal and signal.isVisible
                if @helper.getDistance(signal.k * signal.tickSizeX, signal.k * signal.tickSizeY) >= @helper.distance
                    signal.visible = false
                else
                    signal.x += signal.tickSizeX
                    signal.y += signal.tickSizeY
                    signal.k += 1
        @fpsLabel.text = Math.round(Ticker.getMeasuredFPS())+" fps"
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
    constructor: (minRow, maxRow) ->
        #canvasBackground = document.getElementById "background"
        canvasOwnership = document.getElementById "ownership"
        canvasResources = document.getElementById "resources"
        canvasGrid = document.getElementById "grid"
        canvasPlatforms = document.getElementById "platforms"
        canvasChannels = document.getElementById "channels"
        canvasOverlay = document.getElementById "overlay"
        canvasSignals = document.getElementById "signals"
        canvasOff = document.getElementById "off"
        #canvasUI = document.getElementById "UI"
        @stages = []

        ###
        if canvasBackground?
            @backgroundST = new Stage canvasBackground
            @backgroundDR = new BackgroundDrawer @backgroundST
            @addStage @backgroundST
        ###
        if canvasOwnership?
            @ownershipST = new Stage canvasOwnership
            @addStage @ownershipST
        if canvasResources?
            @resourcesST = new Stage canvasResources
            @addStage @resourcesST
        if canvasGrid?
            @gridST = new Stage canvasGrid
            @addStage @gridST
        if canvasPlatforms?
            @platformsST = new Stage canvasPlatforms
            @addStage @platformsST
        if canvasChannels?
            @channelsST = new Stage canvasChannels
            @addStage @channelsST
        if canvasOverlay?
            @overlayST = new Stage canvasOverlay
            @addStage @overlayST
        if canvasSignals?
            @signalsST = new Stage canvasSignals
            @offST = new Stage canvasOff
            @addStage @signalsST
            @addStage @offST
        ###
        if canvasUI?
            @UIST = new Stage canvasUI
            @addStage @UIST
        ###
        helper = new Drawer @ownershipST, minRow, maxRow
        @boardDR = new BoardDrawer @ownershipST, @resourcesST, @gridST, @platformsST, @channelsST, @overlayST, helper
        @signalsDR = new SignalsDrawer @signalsST, @offST, helper

    addStage: (stage) ->
        @stages.push stage

    clearAll: () ->
        for stage in @stages
            stage.removeAllChildren()
        true

    updateAll: () ->
        for stage in @stages
            stage.update()
        true

#---------------------Interface----------------------#

    # moves signal from field (x,y) in particular direction
    moveSignal: (x, y, direction) ->
        @signalsDR.createSignal(x, y, direction)

    # builds a channel at field (x,y) in given direction
    buildChannel: (x, y, direction, channel) ->
        @boardDR.buildChannel(x, y, direction, channel.state.owner)

    # builds a platform at field (x,y) given a field object, which helps
    # to indicate type of a platform
    buildPlatform: (x, y, platform) ->
        @boardDR.buildPlatform(x, y, platform.type())

    # captures a channel, (x,y) are the coordinates of the player's field
    # channel is the object at (x,y), helps to find the ownership
    # direction indicates the field which will be captured with the channel
    captureChannel: (x, y, direction, channel) ->
        @boardDR.captureChannel(x, y, direction, channel.state.owner)

    # captures a platform at (x,y), field is a field object at (x,y)
    capturePlatform: (x, y, field) ->
        @boardDR.capturePlatform(x, y, field.platform.state.owner)

    # Resets all the canvases, using the current boardState
    # It clears all the stages and. To be discussed whether to clear Signals
    # stage
    setupBoard: (boardState) ->
        @clearAll()
        @signalsDR.setupFPS()
        @signalsDR.setupOffSignals()
        @boardDR.setupBoard(boardState)
        Ticker.useRAF = true
        Ticker.setFPS 60
        @updateAll()

#----------------------------------------#
#--------For test purposes only---------#
window.S.Drawer = Drawer
window.S.Renderer = Renderer
###
player = ObjectFactory.build Types.Entities.Player
manager = new GameManager Backbone.Events, [player], [[2,2]], 8, 15
state = manager.map
console.log state

channelStat =
    state: {
        owner:
            id: 1
    }
    platform: {
        type: () -> 8
        behaviour:
            platformType: {}
        state:
            owner:
                id: 1
        }

window.channelStat = channelStat
window.state = state


$ ->

    if $('#radial').length <= 0   
        renderer = new Renderer 8, 15
        renderer.setupBoard(state)
        window.renderer = renderer
        for y in [0..4]
                for x in [0..4]
                    renderer.moveSignal y, x, 2
        renderer.buildChannel 2, 2, 3, channelStat
        renderer.buildChannel 3, 3, 3, channelStat
        renderer.buildChannel 4, 4, 5, channelStat

    contentWidth = 2000
    contentHeight = 2000
    cellWidth = 100
    cellHeight = 100
    container = document.getElementById("canvasWrapper")
    content = document.getElementById("grid")
    context = renderer.gridST.canvas.getContext("2d")

    render = (left, top, zoom) ->
      content.width = clientWidth
      content.height = clientHeight
      context.clearRect 0, 0, clientWidth, clientHeight
      renderer.gridST.update()

    clientWidth = 0
    clientHeight = 0
    scroller = new Scroller(render,
      zooming: true
    )
    rect = container.getBoundingClientRect()
    scroller.setPosition rect.left + container.clientLeft, rect.top + container.clientTop

    reflow = ->
      clientWidth = container.clientWidth
      clientHeight = container.clientHeight
      scroller.setDimensions clientWidth, clientHeight, contentWidth, contentHeight

    window.addEventListener "resize", reflow, false
    reflow()

    if "ontouchstart" of window
      container.addEventListener "touchstart", ((e) ->
        return  if e.touches[0] and e.touches[0].target and e.touches[0].target.tagName.match(/input|textarea|select/i)
        scroller.doTouchStart e.touches, e.timeStamp
        e.preventDefault()
      ), false
      document.addEventListener "touchmove", ((e) ->
        scroller.doTouchMove e.touches, e.timeStamp, e.scale
      ), false
      document.addEventListener "touchend", ((e) ->
        scroller.doTouchEnd e.timeStamp
      ), false
      document.addEventListener "touchcancel", ((e) ->
        scroller.doTouchEnd e.timeStamp
      ), false
    else
        mousedown = false
        container.addEventListener "mousedown", ((e) ->
            console.log 'poprostu kurwa no nie'
            return  if e.target.tagName.match(/input|textarea|select/i)
            scroller.doTouchStart [
                pageX: e.pageX
                pageY: e.pageY
            ], e.timeStamp
            mousedown = true
        ), false
        document.addEventListener "mousemove", ((e) ->
            console.log 'boże czy Ty to widzisz?'
            return  unless mousedown
            scroller.doTouchMove [
                pageX: e.pageX
                pageY: e.pageY
            ], e.timeStamp
            mousedown = true
        ), false
        document.addEventListener "mouseup", ((e) ->
            console.log "widzę"
            return  unless mousedown
            scroller.doTouchEnd e.timeStamp
            mousedown = false
        ), false
        
        container.addEventListener (if navigator.userAgent.indexOf("Firefox") > -1 then "DOMMouseScroll" else "mousewheel"), ((e) ->
            scroller.doMouseZoom (if e.detail then (e.detail * -120) else e.wheelDelta), e.timeStamp, e.pageX, e.pageY
        ), false


    #if $('#radial').length <= 0   
        #renderer = new Renderer 8, 15
        #renderer.setupBoard(state)
        #window.renderer = renderer
        #for y in [0..4]
                #for x in [0..4]
                    #renderer.moveSignal y, x, 2
        #renderer.buildChannel 2, 2, 3, channelStat
        #renderer.buildChannel 3, 3, 3, channelStat
        #renderer.buildChannel 4, 4, 5, channelStat

###