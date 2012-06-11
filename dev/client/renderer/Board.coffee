class Drawer
    margin: 150
    size: 45
    div: 60

    # horIncrement is a horizontal distance between centers of two hexes divided by two
    # verIncrement is a vertical distance between centers of two hexes
    constructor: (@minRow, @maxRow) ->
        @horIncrement = Math.ceil Math.sqrt(3)*@size/2
        @verIncrement = Math.ceil 3*@size/2
        @diffRows = @maxRow - @minRow
        @distance = 2*@horIncrement
        @width = @margin+(@maxRow-1)*@distance+@horIncrement
        @height = @margin+(@diffRows)*2*@verIncrement+@size
        @ticksX = []
        @ticksY = []
        @offsetX = []
        @offsetY = []
        @scrollX = 0
        @scrollY = 0
        @setupOffsets()
        @setupTicks()
        @viewportHeight = 0
        @viewportWidth = 0

        @directionModificators =
          0: [-1, -1]
          1: [0, -1]
          2: [1, 0]
          3: [1, 1]
          4: [0, 1]
          5: [-1, 0]

        @canvasDimensions = {}
        @canvasDimensions.x =
            2*(@margin-@horIncrement) +
            @maxRow * @distance + @margin

        @canvasDimensions.y =
            (@margin+@size) +
            (@diffRows * 2 + 1) * @verIncrement + @margin

    # Setups table of offsets according to direction
    setupOffsets: () ->
        @offsetX = [-@horIncrement, @horIncrement, 2*@horIncrement, @horIncrement, -@horIncrement, -2*@horIncrement, 0]
        @offsetY = [-@verIncrement, -@verIncrement, 0, @verIncrement, @verIncrement, 0, 0]

    # Setups table of tick sizes according to the direction
    setupTicks: () ->
        for i in [0..5]
            @ticksX[i] = @offsetX[i]/@div
            @ticksY[i] = @offsetY[i]/@div
        true

    setViewport: (width, height) ->
        @viewportHeight = height
        @viewportWidth = width

    setScroll: (x, y) ->
        @scrollX = x
        @scrollY = y

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
        new Point(offset + 2*x*@horIncrement - @scrollX, @margin + y*@verIncrement - scrollY)

    # Arguments: point with canvas coordinates and direction (0..5)
    # Returns canvas coordinates of destination point in particular direction
    getDestination: (point, direction) ->
        new Point(point.x + @offsetX[direction], point.y + @offsetY[direction])

    # Arguments: point with canvas coordinates (which is a center of a particular hex)
    # Returns board coordinates of a particular point
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

class BoardDrawer extends Drawer
    constructor: (@eventBus, @off2ST, @ownershipST, @resourcesST, @gridST, @platformsST, @channelsST, @overlayST, minRow, maxRow, @players, @myPlayer) ->
        super minRow, maxRow
        @uiHandler = new UIHandler @overlayST, minRow, maxRow
        @colors = ["#274E7D", "#900020", "#FFA000", "#B80049", "#00A550", "#9999FF", "#367588", "#FFFFFF"]
        @stages = [@gridST, @overlayST, @ownershipST, @resourcesST, @platformsST, @channelsST]
        @visibility = []

    addPlayer: (player) ->
        @players.push player

    updateAll: () ->
        for i in [1..5]
            stage = @stages[i]
            @stage.updateCache()
            @stage.update()

    buildPlatform: (x, y, type) ->
        point = @getPoint(x, y)
        @drawPlatform(point, type)
        @updateAll()

    capturePlatform: (x, y, ownerid) ->
        point = @getPoint x, y
        @drawOwnership point, ownerid

    buildChannel: (x, y, direction, ownerid) ->
        point = @getPoint(x, y)
        destination = @getDestination(point, direction)
        @drawChannel(point, direction)
        @drawOwnership(destination, ownerid)

    captureChannel: (x, y, direction, ownerid) ->
        point = @getPoint(x, y)
        destination = @getDestination(point, direction)
        @drawOwnership(destination, ownerid)
        @updateAll()

    changeOwnership: (x, y, ownerid) ->
        point = @getPoint(x, y)
        @drawOwnership(point, ownerid)
        @setFog(x, y, point, ownerid)
        @updateAll()

    drawFog: (point) ->
        g = new Graphics()
        g.beginFill("#000000")
        g.drawPolyStar(0, 0, @size, 6, 0, 90)
        overlay = new Shape g
        overlay.x = point.x
        overlay.y = point.y
        overlay.alpha = 0.2
        @overlayST.addChild overlay

    setFog: (x, y, point, ownerid) ->
        if ownerid is @myPlayer.id or not (ownerid?)
            for i in [0..6]
                fog = @overlayST.getObjectUnderPoint point.x + @offsetX[i], point.y + @offsetY[i]
                if fog.visible
                    fog.visible = false
                    for j in [2..5]
                        stage = @stages[j]
                        x = point.x + @offsetX[i]
                        y = point.y + @offsetY[i]
                        obj = stage.getObjectUnderPoint x, y
                        console.log x, y, obj
                        if obj?
                            obj.alpha = 1

    drawOwnership: (point, ownerid) ->
        g = new Graphics()
        g.setStrokeStyle(3)
        if ownerid?
            g.beginStroke(@colors[_.indexOf(@players, ownerid)])
            .drawPolyStar(point.x, point.y, @size*0.95, 6, 0, 90)
            shape = new Shape g
            #shape.visible = false
            @ownershipST.addChild shape
            if ownerid is @myPlayer.id
                @visibility.push [@getCoords(point), point]
        else
            g.beginStroke("#616166")
            .drawPolyStar(point.x, point.y, @size, 6, 0, 90)
            @gridST.addChild new Shape g

    drawPlatform: (point, type) ->
        #g = new Graphics()
        switch type
            when S.Types.Entities.Platforms.HQ then @setBitmap(point, 0)#g.beginFill("#C5B356")
            when S.Types.Entities.Platforms.Normal then @setBitmap(point, 1)#g.beginFill("#A6B4B0")
        #g.drawPolyStar(point.x, point.y, 2*@size/3, 6, 0, 90)
        #@platformsST.addChild new Shape g

    setBitmap: (point, type) ->
        b = @off2ST.getChildAt(type).clone()
        b.visible = true
        b.x = point.x
        b.y = point.y
        console.log b.x, b.y
        @platformsST.addChild b

    drawResource: (point, resource) ->
        g = new Graphics()
        switch resource
            when S.Types.Resources.Gold then g.beginFill("#00FF00")
            when S.Types.Resources.Food then g.beginFill("#0FFFF0")
            when S.Types.Resources.Resource then g.beginFill("#FFFFFF")
        g.drawCircle(point.x, point.y, 6)
        shape = new Shape g
        #shape.visible = false
        @resourcesST.addChild shape

    drawChannel: (point, direction) ->
        destination = @getDestination(point, direction)
        g = new Graphics()
        g.moveTo(point.x, point.y)
            .setStrokeStyle(3)
            .beginStroke("#FFFF00")
            .beginFill("#FFFF00")
            .lineTo(destination.x, destination.y)
        shape = new Shape g
        #shape.visible = false
        @channelsST.addChild shape

    drawHex: (point, field) ->
        @drawFog point
        @drawOwnership point
        if field.platform.type?
            @drawOwnership point, field.platform.state.owner.id
        if field.resource.behaviour?
            @drawResource point, field.resource.type()
        if field.platform.type?
            @drawPlatform point, field.platform.type()
        #@uiHandler.drawOverlay point

    setupBoard: (boardState) ->
        for j in [0 ... (2*@diffRows + 1)]
            for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
                point = @getPoint(i, j)
                console.log i, j
                @drawHex(point, boardState.getField(i, j))
                for k in [0 .. 5]
                    if boardState.getChannel(i, j, k)?.state?
                        @drawChannel(point, k)
        for coords in @visibility
            @setFog coords[0].x, coords[0].y, coords[1]
        @toogleCache true
        #@uiHandler.toogleCache true

    toogleCache: (status) ->
        for i in [0..5]
            stage = @stages[i]
            if status
                stage.cache(0,0, @width+5, @height+5)
            else
                stage.uncache()
        true

class UIHandler extends Drawer
    constructor: (@stage, minRow, maxRow) ->
        super minRow, maxRow
        @update = false
        #@stage.enableMouseOver(20)
        #@stage.onMouseOver = @mouseOverField
        #@stage.onMouseOut = @mouseOutField
        #@overlay = @drawOverlay(new Point 0, 0)
        #Ticker.addListener this
        @k = 0

    drawOverlay: (point) ->
        g = new Graphics()
        g.beginFill("#FFFF00")
        g.drawPolyStar(0, 0, @size, 6, 0, 90)
        overlay = new Shape g
        overlay.x = point.x
        overlay.y = point.y
        overlay.alpha = 0.01
        @stage.addChild overlay

    mouseOverField: (event) =>
        console.log event
        x = event.stageX
        y = event.stageY
        if x?
            fieldCoords = @getCoords(x,y)
            point = @getPoint(fieldCoords.x, fieldCoords.y)
            @overlay.x = point.x
            @overlay.y = point.y
            @overlay.alpha = 0.2
            @update = true
        #event.target.alpha = 0.2
        #event.target.updateCache()
        #@update = true

    fun: () ->
        x = @stage.mouseX
        y = @stage.mouseY
        if x?
            fieldCoords = @getCoords(new Point(x,y))
            point = @getPoint(fieldCoords.x, fieldCoords.y)
            @overlay.x = point.x
            @overlay.y = point.y
            @overlay.alpha = 0.2
            console.log @overlay
            @update = true
            @k++
        if @k is 5
            Ticker.setPaused true

    mouseOutField: (event) =>
        console.log "out"
        event.target.alpha = 0.01
        event.target.updateCache()
        @update = true

    tick: () ->
        #@fun()
        if(@update)
            @update = false
            @stage.update()

    toogleCache: (status) ->
        length = @stage.getNumChildren() - 1
        for i in [0..length]
            shape = @stage.getChildAt i
            if status
                shape.cache(-@horIncrement, -@size, (@distance), (@size)*2)
            else
                shape.uncache()
        true

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

class SignalsDrawer extends Drawer
    signalRadius: 8
    signalCount: 50

    constructor: (@stage, @offStage, minRow, maxRow) ->
        super minRow, maxRow
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
        signal.tickSizeX = @ticksX[dir]
        signal.tickSizeY = @ticksY[dir]
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
        point = @getPoint(x, y)
        @drawSignal(point, direction)
        @stage.update()

    tick: () ->
        for signal in @stage.children
            if signal.isSignal and signal.isVisible
                if @getDistance(signal.k * signal.tickSizeX, signal.k * signal.tickSizeY) >= @distance
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
    constructor: (eventBus, minRow, maxRow, players, myPlayer) ->
        #canvasBackground = document.getElementById "background"
        canvasOwnership = document.getElementById "ownership"
        canvasResources = document.getElementById "resources"
        canvasPlatforms = document.getElementById "platforms"
        canvasGrid = document.getElementById "grid"
        canvasChannels = document.getElementById "channels"
        canvasOverlay = document.getElementById "overlay"
        canvasSignals = document.getElementById "signals"
        canvasOff = document.getElementById "off"
        canvasOff2 = document.getElementById "off2"
        #canvasUI = document.getElementById "UI"
        @stages = []
        @bitmaps = ["/img/hq.png", "/img/platform.png"]
        @boardLoaded = $.Deferred()
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
        if canvasPlatforms?
            @platformsST = new Stage canvasPlatforms
            @off2ST = new Stage canvasOff2
            @addStage @platformsST
        if canvasGrid?
            @gridST = new Stage canvasGrid
            @addStage @gridST
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
        imagesLoaded = $.Deferred()
        @loadImages imagesLoaded
        $.when(imagesLoaded.promise()).done =>
            console.log 'all Images have been loaded'
            @boardDR = new BoardDrawer eventBus, @off2ST, @ownershipST, @resourcesST, @gridST, @platformsST, @channelsST, @overlayST, minRow, maxRow, players, myPlayer
            @signalsDR = new SignalsDrawer @signalsST, @offST, minRow, maxRow
            @boardLoaded.resolve()

    loadImages: (dfd) ->
        k = 0
        setImg = (event) =>
            bitmap = new Bitmap event.target
            bitmap.visible = false
            bitmap.regX = 35
            bitmap.regY = 40
            @off2ST.addChild bitmap
            k++
            if k is @bitmaps.length
                console.log 'image loaded event'
                dfd.resolve()

        loadBitmap = (src) =>
            img = new Image
            img.src = src
            img.onload = setImg

        for src in @bitmaps
            loadBitmap src

    addPlayer: (player) ->
        @boardDR.addPlayer(player)

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
        console.log channel
        @boardDR.buildChannel(x, y, direction, channel.state.owner.id)

    # builds a platform at field (x,y) given a field object, which helps
    # to indicate type of a platform
    buildPlatform: (x, y, platform) ->
        @boardDR.buildPlatform(x, y, platform.type())

    # captures a channel, (x,y) are the coordinates of the player's field
    # channel is the object at (x,y), helps to find the ownership
    # direction indicates the field which will be captured with the channel
    captureChannel: (x, y, direction, state) ->
        @boardDR.captureChannel(x, y, direction, state.owner.id)

    # captures a platform at (x,y), field is a field object at (x,y)
    capturePlatform: (x, y, state) ->
        @boardDR.capturePlatform(x, y, state.owner.id)

    changeOwnership: (x, y, owner) ->
        @boardDR.capturePlatform(x, y, owner.id)

    # Resets all the canvases, using the current boardState
    # It clears all the stages and. To be discussed whether to clear Signals
    # stage
    setupBoard: (boardState) ->
        #@clearAll()
        @signalsDR.setupFPS()
        @signalsDR.setupOffSignals()
        @boardDR.setupBoard(boardState)
        Ticker.useRAF = true
        Ticker.setFPS 60
        @updateAll()

window.S.Drawer = Drawer
window.S.Renderer = Renderer

#----------------------------------------#
#--------For test purposes only---------#
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
