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

        @directionModUpper = [[-1, -1], [0, -1], [1, 0], [1, 1], [0, 1], [-1, 0],[0, 0]]
        @directionModLower = [[0, -1], [1, -1], [1, 0], [0, 1], [-1, 1], [-1, 0],[0, 0]]

        @invisibleTerrain = {}

        @canvasDimensions = {}
        @canvasDimensions.x = $( 'canvas' ).first().outerWidth()
        ###
        2*(@margin-@horIncrement) +
        @maxRow * @distance + @margin
        ###

        @canvasDimensions.y = $( 'canvas' ).first().outerHeight()
        ###
        (@margin+@size) +
        (@diffRows * 2 + 1) * @verIncrement + @margin
        ###

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

    modifyCoords: (x, y, dir) ->
        if y < @diffRows or (y is @diffRows and dir < 3)
            mod = @directionModUpper[dir]
        else if y > @diffRows or (y is @diffRows and dir >= 3)
            mod = @directionModLower[dir]
        [x + mod[0], y + mod[1]]

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
        new Point(offset + 2*x*@horIncrement, @margin + y*@verIncrement)

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

    contains: (list, elem) ->
        for e in list
            if _.isEqual e, elem
                return true
        false

    without: (list, elem) ->
        for i in [0..list.length]
            e = list[i]
            if _.isEqual e, elem
                return list.splice(0, i).concat(list.splice i+1)
        list

    union: (list1, list2) ->
        for elem in list2
            if not @contains list1, elem
                list1.push elem
        list1

    difference: (list1, list2) ->
        for elem in list2
            list1 = @without list1, elem
        list1

class BoardDrawer extends Drawer
    constructor: (@bitmapsST, @stages, minRow, maxRow, @players, @myPlayer) ->
        super minRow, maxRow
        @gridST = @stages[0]
        @fogST = @stages[1]
        @ownershipST = @stages[2]
        @resourcesST = @stages[3]
        @platformsST = @stages[4]
        @channelsST = @stages[5]
        @colors = ["#274E7D", "#900020", "#FFA000", "#B80049", "#00A550", "#9999FF", "#367588", "#FFFFFF"]


        @visibility = []
        @ownership = []

        @elements = {}
        @fog = {}

        @bitmaps = []
        @shapes = []

        @setShapes()
        @invisibleTerrain = @fogST
#------------FOG SWITCH-------------#
        @fogON = true
#------------FOG SWITCH-------------#

#--------------------#
    setShapes: () ->
        drawFog = () =>
            g1 = new Graphics()
            g1.beginFill("#000000")
             .drawPolyStar(0, 0, @size*1.008, 6, 0, 90)
            fog = new Shape g1
            fog.alpha = 0.6
            fog.regX = @horIncrement
            fog.regY = @size
            @shapes[0] = fog
            @shapes[0].cache(-@horIncrement, -@size, (@distance), (@size)*2)
        drawGrid = () =>
            g2 = new Graphics()
            g2.setStrokeStyle(3)
             .beginStroke("#616166")
             .drawPolyStar(0, 0, @size, 6, 0, 90)
            grid = new Shape g2
            grid.regX = @horIncrement
            grid.regY = @size
            @shapes[1] = grid
            @shapes[1].cache(-@horIncrement, -@size, (@distance), (@size)*2)
        drawFog()
        drawGrid()

    addElement: (x, y, e) ->
        @elements[x] ?= []
        @elements[x][y] ?= []
        @elements[x][y].push e

    addFog: (x, y, e) ->
        @fog[x] ?= []
        @fog[x][y] = e

    addPlayer: (player) ->
        @players.push player

    updateAll: () ->
        for i in [1..5]
            stage = @stages[i]
            stage.updateCache()
            stage.update()

    clearData: () ->
        @visibility = []
        @ownership = []
        @elements = {}
        @fog = {}

#--------------------#

    buildPlatform: (x, y, type) ->
        point = @getPoint(x, y)
        @addElement x, y, @drawPlatform(point, type)
        @platformsST.updateCache()
        @platformsST.update()

    buildChannel: (x, y, direction, ownerid) ->
        point = @getPoint(x, y)
        @addElement x, y, @drawChannel(point, direction)
        @channelsST.updateCache()
        @channelsST.update()
        #console.log "[BOARD]:visibility, ownership", @visibility, @ownership

    captureOwnership: (x, y, ownerid) ->
        point = @getPoint(x, y)
        @addElement x, y, @drawOwnership(point, ownerid)
        if @fogON
            @setVisibility [x, y], false, ownerid
        @updateAll()

    changeOwnership: (x, y, ownerid) ->
        point = @getPoint(x, y)
        @addElement x, y, @drawOwnership(point, ownerid)
        if @fogON
            @setVisibility [x, y], true, ownerid
        @updateAll()

#--------------------#

    drawFog: (point) ->
        fog = @shapes[0].clone()
        fog.x = point.x
        fog.y = point.y
        @fogST.addChild fog
        fog

    drawGrid: (point) ->
        border = @shapes[1].clone()
        border.x = point.x
        border.y = point.y
        @gridST.addChild border
        border

    drawOwnership: (point, ownerid) ->
        draw = (ownerid) =>
            g = new Graphics()
            g.setStrokeStyle(4)
             .beginStroke(@colors[_.indexOf(@players, ownerid)])
             .drawPolyStar(0, 0, @size*0.93, 6, 0, 90)
            new Shape g
        owner = draw(ownerid)
        if @fogON
            owner.visible = false
        owner.x = point.x
        owner.y = point.y
        @ownershipST.addChild owner
        owner

    drawPlatform: (point, type) ->
        draw = (type) =>
            switch type
                when S.Types.Entities.Platforms.HQ then bitmap = @bitmapsST.getChildAt(2).clone()
                when S.Types.Entities.Platforms.Normal then bitmap = @bitmapsST.getChildAt(4).clone()
            bitmap
        bitmap = draw(type)
        if @fogON
            bitmap.visible = false
        else
            bitmap.visible = true
        bitmap.x = point.x
        bitmap.y = point.y
        @platformsST.addChild bitmap
        bitmap

    drawResource: (point, type) ->
        draw = (type) =>
            switch type
                when S.Types.Resources.Gold
                    resource = @bitmapsST.getChildAt(1).clone()
                    resource.regX = 30
                    resource.regY = 35
                when S.Types.Resources.Food then resource = @bitmapsST.getChildAt(0).clone()
                when S.Types.Resources.Resources then resource = @bitmapsST.getChildAt(3).clone()
            resource
        resource = draw(type)
        if @fogON
            resource.visible = false
        else
            resource.visible = true
        resource.x = point.x
        resource.y = point.y
        @resourcesST.addChild resource
        resource

    drawChannel: (point, direction) ->
        draw = (point, direction) =>
            destination = @getDestination(point, direction)
            g = new Graphics()
            g.moveTo(point.x, point.y)
             .setStrokeStyle(8,1)
             .beginStroke("#564334")
             .lineTo(destination.x, destination.y)
             .endStroke()
             .moveTo(point.x, point.y)
             .setStrokeStyle(5,1)
             .beginStroke("#CFB590")
             .lineTo(destination.x, destination.y)
             .endStroke()
             .setStrokeStyle(2,1)
             .beginStroke("#564334")
             .beginFill("#CFB590")
             .drawCircle(point.x, point.y, 4)
             .endStroke()
             .setStrokeStyle(2,1)
             .beginStroke("#564334")
             .beginFill("#CFB590")
             .drawCircle(destination.x, destination.y, 4)
            new Shape g
            #road = @bitmapsST.getChildAt(5).clone()
            #road.regX = 0
            #road.regY = 0
            #road.rotation = 60 * ((direction+4)%6)
            #road
        channel = draw(point, direction)
        channel.alpha = 0.7
        if @fogON
            channel.visible = false
        else
            channel.visible = true
        #channel.x = point.x
        #channel.y = point.y
        @channelsST.addChild channel
        channel
#--------------------#

    setFog: (point, status) ->
        if @fog[point[0]]?[point[1]]?
            @fog[point[0]][point[1]].visible = status
            if @elements[point[0]]?[point[1]]?
                for elem in @elements[point[0]][point[1]]
                    elem.visible = not status

    setVisibility: (point, status, ownerid) ->
        array = []
        for i in [0..6]
            array.push (@modifyCoords point[0], point[1], i)
        if ownerid is @myPlayer.id and not (@contains @ownership, point)
            #cl = @difference array.slice(0), @visibility
            #console.log "BOARD:DIFFERENCE", array, array.length, @visibility, @visibility.length, cl, cl.length
            for p in array
                @setFog p, false
            @visibility = @union @visibility, array
            @ownership.push point
        else
            if status
                if @contains @visibility, point
                    if @elements[point[0]]?[point[1]]?
                        for elem in @elements[point[0]][point[1]]
                            elem.visible = true
            else
                @ownership = @without @ownership, point
                @visibility = @getVisibility @ownership
                for p in (@difference array, @visibility)
                    if @fog[point[0]]?[point[1]]?
                        @fog[point[0]][point[1]].visible = true

    getVisibility: (ownership) ->
        visibility = []
        for point in ownership
            array = []
            for i in [0..6]
                array.push @modifyCoords point[0], point[1], i
            visibility = @union visibility, array
        visibility

#--------------------#
    setupHex: (point, x, y, field) ->
        if @fogON
            @addFog x, y, @drawFog point
        @drawGrid point
        if field.resource.behaviour?
            @addElement x, y, @drawResource point, field.resource.type()
        @setupPlatform point, x, y, field
        @setupChannels point, x, y, field

    setupPlatform: (point, x, y, field) ->
        if field.platform.type?
            @addElement x, y, @drawPlatform point, field.platform.type()
            if field.platform.type() is S.Types.Entities.Platforms.HQ and not (@contains @ownership, [x, y])
                ownerid = field.platform.state.owner.id
                @addElement x, y, @drawOwnership point, ownerid
                if ownerid is @myPlayer.id
                    @ownership.push [x, y]

    setupChannels: (point, x, y, field) ->
        for k in [0..5]
            channel = field.channels[k]
            if channel?
                @addElement x, y, @drawChannel(point, k)
                newCoords = @modifyCoords x, y, k
                if not (@contains @ownership, newCoords)
                    ownerid = channel.state.owner.id
                    @addElement newCoords[0], newCoords[1], @drawOwnership @getDestination(point,k), ownerid
                    if ownerid is @myPlayer.id
                        @ownership.push newCoords

    setupBoard: (boardState) ->
        for j in [0 ... (2*@diffRows + 1)]
            for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
                point = @getPoint(i, j)
                @setupHex(point, i, j, boardState.getField(i, j))
        if @fogON
            @toogleFog true
        @toogleCache true

    toogleFog: (status) ->
        if status
            @visibility = @getVisibility @ownership
            for point in @visibility
                @setFog point, false

    toogleCache: (status) ->
        for i in [0..5]
            stage = @stages[i]
            if status
                stage.cache(0,0, @width+5, @height+5)
            else
                stage.uncache()
        true

#--------------------#

class OffSignals
    signalRadius: 7
    signalCount: 150

    constructor: (@stage, @players) ->
        @stage.snapToPixelEnabled = true
        @colors = ["#274E7D", "#900020", "#FFA000", "#B80049", "#00A550", "#9999FF", "#367588", "#FFFFFF"]

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
        g.setStrokeStyle(2)
            #.beginStroke("#C7F66F")
            #.beginFill("#84B22D")
            .beginStroke("#0F4DA8")
            .beginFill("#437DD4")
            .drawCircle(0, 0, @signalRadius)
        shape = new Shape g
        shape.snapToPixel = true
        shape.visible = false
        shape.isSignal = true
        shape.alpha = 0.8
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

    constructor: (@eventBus, @stage, @offStage, minRow, maxRow, @boardDR, @players) ->
        super minRow, maxRow
        @offSignals = new OffSignals @offStage, @players
        @people = new S.People @eventBus,
            distance: 80
            time: 400

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
        signal.tickSizeX = @offsetX[dir]/Ticker.getMeasuredFPS()
        signal.tickSizeY = @offsetY[dir]/Ticker.getMeasuredFPS()
        signal.visible = true
        signal.k = 0

    drawWorker: (x, y, direction) ->
        if @contains @boardDR.visibility, [x, y]
            @people.walk x, y, direction

    getSignal: () ->
        for sig in @stage.children
            if sig.isSignal and not sig.visible
                #console.log "used"
                return sig
        null

    createSignal: (x, y, direction) ->
        if @contains @boardDR.visibility, [x, y]
            point = @getPoint(x, y)
            @drawSignal(point, direction)
            @stage.update()

    tick: () ->
        for signal in @stage.children
            if signal.isSignal and signal.isVisible
                signal.visible = true
                if @getDistance(signal.k * signal.tickSizeX, signal.k * signal.tickSizeY) >= @distance
                    signal.visible = false
                else
                    signal.x += signal.tickSizeX
                    signal.y += signal.tickSizeY
                    signal.k += 1
        @fpsLabel.text = Math.round(Ticker.getMeasuredFPS())+" fps"
        @stage.update()

class Renderer
    constructor: (eventBus, minRow, maxRow, players, myPlayer) ->
        canvasOwnership = document.getElementById "ownership"
        canvasResources = document.getElementById "resources"
        canvasPlatforms = document.getElementById "platforms"
        canvasGrid = document.getElementById "grid"
        canvasChannels = document.getElementById "channels"
        canvasFog = document.getElementById "fog"
        canvasSignals = document.getElementById "signals"
        canvasOff = document.getElementById "off"
        canvasBitmaps = document.getElementById "bitmaps"
        @bitmaps = ["/img/Food.png", "/img/Gold.png", "/img/hq.png", "/img/iron.png", "/img/platform.png", "/img/road.png"]
        @boardLoaded = $.Deferred()

        if canvasOwnership?
            @ownershipST = new Stage canvasOwnership
        if canvasResources?
            @resourcesST = new Stage canvasResources
        if canvasPlatforms?
            @platformsST = new Stage canvasPlatforms
            @bitmapsST = new Stage canvasBitmaps
        if canvasGrid?
            @gridST = new Stage canvasGrid
        if canvasChannels?
            @channelsST = new Stage canvasChannels
        if canvasFog?
            @fogST = new Stage canvasFog
        if canvasSignals?
            @signalsST = new Stage canvasSignals
            @offST = new Stage canvasOff

        @stages = [@gridST, @fogST, @ownershipST, @resourcesST, @platformsST, @channelsST, @signalsST]

        imagesLoaded = $.Deferred()
        @loadImages imagesLoaded
        $.when(imagesLoaded.promise()).done =>
            console.log '[Renderer] all Images have been loaded'
            boardStages = [@gridST, @fogST, @ownershipST, @resourcesST, @platformsST, @channelsST]
            @boardDR = new BoardDrawer @bitmapsST, boardStages, minRow, maxRow, players, myPlayer
            @signalsDR = new SignalsDrawer eventBus, @signalsST, @offST, minRow, maxRow, @boardDR, players
            @boardLoaded.resolve()

    loadImages: (dfd) ->
        count = 0

        compare = (a, b) =>
            if a.image.src >= b.image.src
                1
            else if a.image.src < b.image.src
                -1

        setImg = (event) =>
            bitmap = new Bitmap event.target
            bitmap.visible = false
            bitmap.regX = 35
            bitmap.regY = 40
            @bitmapsST.addChild bitmap
            count++
            if count is @bitmaps.length
                @bitmapsST.sortChildren compare
                console.log '[Renderer] image loaded event', count
                dfd.resolve()

        loadBitmap = (bitmap) =>
            img = new Image
            img.src = bitmap
            img.onload = setImg

        for bitmap in @bitmaps
            loadBitmap bitmap

    addPlayer: (player) ->
        @boardDR.addPlayer(player)

    clearAll: () ->
        for stage in @stages
            stage.removeAllChildren()
        true

    updateAll: () ->
        for stage in @stages
            stage.update()
        true
    #Doesnt work so far
    switchFog: (status) ->
        @boardDR.fogON = status

#---------------------Interface----------------------#

    # moves signal from field (x,y) in particular direction
    moveSignal: (x, y, direction) ->
        #@signalsDR.createSignal(x, y, direction)
        @signalsDR.drawWorker(x, y, direction)
    # builds a channel at field (x,y) in given direction
    buildChannel: (x, y, direction, channel) ->
        @boardDR.buildChannel(x, y, direction, channel.state.owner.id)

    # builds a platform at field (x,y) given a field object, which helps
    # to indicate type of a platform
    buildPlatform: (x, y, platform) ->
        @boardDR.buildPlatform(x, y, platform.type())

    # captures a channel, (x,y) are the coordinates of the player's field
    # channel is the object at (x,y), helps to find the ownership
    # direction indicates the field which will be captured with the channel
    captureChannel: (x, y, direction, state) ->
        @boardDR.captureOwnership(x, y, state.owner.id)

    # captures a platform at (x,y), field is a field object at (x,y)
    captureOwnership: (x, y, ownerid) ->
        @boardDR.captureOwnership(x, y, ownerid)

    # changes ownership of the field at x, y
    changeOwnership: (x, y, ownerid) ->
        @boardDR.changeOwnership(x, y, ownerid)

    # Resets all the canvases, using the current boardState
    # It clears all the stages and. To be discussed whether to clear Signals
    # stage
    setupBoard: (boardState) ->
        @clearAll()
        @signalsDR.setupFPS()
        @boardDR.clearData()
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
