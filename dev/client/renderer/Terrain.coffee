class Terrain extends S.Drawer
  constructor: ( @events, id, @minRow, @maxRow, map, useAWorker ) ->
    canvas = document.getElementById id
    @stage = new Stage canvas

    canvas2 = document.getElementById 'water'
    @waterStage = new Stage canvas2

    if useAWorker
      @worker = new Worker '/js/TerrainWorker.js'
      @worker.postMessage()

      @worker.addEventListener('message', ( e ) ->
        data = e.data

      , false)

    @n = 1
    @bitmaps = {}

    @loading = new $.Deferred()

    @heightMap = @events.game.map.heightMap
    @shadowMap = []
    @blendMasks = {}

    @readyDefer = new $.Deferred()

    @typesOfTerrain = [
      'Dirt',
      'Grass',
      'Water',
      'Deepwater',
      'Sand',
      'Rocks',
      'Forest',
      'Snow'
    ]

    #colours are in hsl :P
    @Config =
      colours:
        Dirt: [24, 32, 30]
        Sand: [35, 40, 69]
        Water: [180, 51, 38]
        Deepwater: [193, 94, 28]
        Rocks: [60,1,49]
        Grass: [57, 42, 44]
        Forest: [84, 27, 25]
        Snow: [180,16,96]
      modifiers:
        h: 1
        s: 10
        l: 2

    super @minRow, @maxRow

    @heightScale = Math.round(@canvasDimensions.x / @events.game.map.heightMapSize)

    @bitmapWidth = @distance
    @bitmapHeight = @size*2

    @previousHitTest = [0, 0]

    @hitHexMap = new Shape()
    @hitHexMap.graphics
      .beginFill( "#FFF" )
      .drawPolyStar(0, 0, @size, 6, 0, 90)
    @hitHexMap.visible = false

    @hitBitmap = null

    #offset fix
    @stage.x = -@horIncrement
    @stage.y = -@size

    @stage.addChild @hitHexMap
    @stage.update()

  isReady: () =>
    @readyDefer.promise()

  createBitmapCanvas: (width = @bitmapWidth, height = @bitmapHeight) =>
    can = $( "<canvas width=#{ width } height=#{ height } />" )
        .appendTo( 'body' ).hide()

    can[0]

  setupBoard: ( boardState ) ->
    for j in [0 ... (2*@diffRows + 1)]
      for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
        for k in [0..2]
          if boardState.getChannel(i, j, k)?.state?
            [i2, j2] = @events.game.map.directionModificators i, j, k

            @generateRoad i, j, i2, j2

  randomTerrain: () ->
    index = Math.floor((Math.random() * 100) % @typesOfTerrain.length)
    @typesOfTerrain[index]

  getFieldBitmap: ( type, n=1 ) ->
    if not @bitmaps[type]? or @n != n
      @generateFieldBitmap type, n

    @bitmaps[type]

  applyBlendMasks: () ->
    cwidth = @canvasDimensions.x
    cheight = @canvasDimensions.y

    context = @stage.canvas.getContext '2d'
    terrainData = context.getImageData 0, 0, cwidth, cheight

    @generateBlendMasks()

    for j in [0 ... (2*@diffRows + 1)]
      for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
        terrain = @getTerrain i, j
        terrains = []

        for k in [0...6]
          [i2, j2] = @events.game.map.directionModificators i, j, k

          terrains[k] = null

          if @events.getField i2, j2
            terrains[k] = @getTerrain i2, j2

        for k in [0...6]
          mask = ''

          km = k + 6

          t1 = terrains[(km-1)%6]
          t2 = terrains[(km)%6]
          t3 = terrains[(km+1)%6]

          if t1? and t1 isnt terrain
            mask += 'l'

          if t2? and t2 isnt terrain
            mask += 'f'

          if t3? and t3 isnt terrain
            mask += 'r'

          if mask.length > 0 and mask isnt 'lr' and mask isnt 'l' and mask isnt 'r'
            p = @getPoint i, j
            maskObj = @blendMasks[mask].clone()
            console.log "[Terrain] apply a mask"
            @applyBlendMask maskObj, t2, p.x, p.y, k

  applyBlendMask: ( mask, terrain, x, y, k, width = @size, height = @size ) =>
    cwidth = @canvasDimensions.x
    cheight = @canvasDimensions.y

    mask.regX = Math.round width/2
    mask.regY = Math.round @size - @horIncrement
    mask.rotation = Math.PI/2 + Math.PI/3 * k
    mask.x = x
    mask.y = y

    maskCanvas = @createBitmapCanvas cwidth, cheight
    maskContext = maskCanvas.getContext '2d'
    maskStage = new Stage maskCanvas
    maskStage.addChild mask
    maskStage.update()
    maskData = maskContext.getImageData 0, 0, cwidth, cheight

    $( maskCanvas ).remove()

    #now mask is over correct are of the board, get terrain to blend with
    blendTerrain = @getFieldBitmap terrain
    blendCanvas = @createBitmapCanvas cwidth, cheight
    blendContext = blendCanvas.getContext '2d'
    blendStage = new Stage blendCanvas
    blendStage.addChild blendTerrain
    blendTerrain.x = x
    blendTerrain.y = y
    blendStage.update()
    blendData = blendContext.getImageData 0, 0, cwidth, cheight

    $( blendCanvas ).remove()

    #get canvas image you will be blending
    context = @stage.canvas.getContext '2d'
    terrainData = context.getImageData 0, 0, cwidth, cheight

    for xp in [x - @size...x + @size]
      for yp in [y - @size...y + @size]
        [r, g, b, a] = @getPixel maskData, xp, yp

        if a > 0
          [r1, g1, b1, a1] = @getPixel blendData, xp, yp
          [r2, g2, b2, a2] = @getPixel terrainData, xp, yp

          w = a/255

          r3 = Math.round r2 * w + r1 * (1-w)
          g3 = Math.round g2 * w + g1 * (1-w)
          b3 = Math.round b2 * w + b1 * (1-w)

          @setPixel terrainData, xp, yp, [r3, g3, b3, a2]

    newTerrain = @createBitmapObjFromBitmap terrainData, cwidth, cheight

    #add terrain back to the game
    @stage.removeAllChildren()
    @stage.addChild newTerrain
    @stage.update()

  generateBlendMasks: () ->
    steps = 8
    h = 0.6
    range = 8

    drawBlendMask = ( bitmap, points, n ) =>
      for x in [0...@size]
        for y in [0...@size]
          @setPixel bitmap, x, y, [0,0,0,255]

      #draw missing triangle on the left side of the image
      if n == 1 or n == 2
        x1 = 0
        y1 = @size - 1
        x2 = Math.round @size/4
        y2 = @size - Math.round( Math.sqrt(3)*@size/4 )

        gradientY = (y2 - y1) / (x2 - x1)

        for x in [x1..x2]
          cY = y1

          for y in [0...cY]
            @setPixel bitmap, x, y, [0,0,0,0]

          cY = Math.round cY + gradientY

      #draw missing triangle on the right side of the image
      if n == 3 or n == 2
        x2 = @size-1
        y2 = @size-1
        x1 = Math.round 3*@size/4
        y1 = @size - Math.round( Math.sqrt(3)*@size/4 )

        gradientY = (y2 - y1) / (x2 - x1)

        for x in [x1..x2]
          cY = y1

          for y in [0...cY]
            @setPixel bitmap, x, y, [0,0,0,0]

          cY = Math.round cY + gradientY

      for i in [0...points.length - 1]
        [xp, yp] = points[i]
        [xp2, yp2] = points[i+1]

        gradientY = (yp2-yp)/(xp2-xp)

        for x in [xp...xp2]
          cY = yp
          alpha = 0

          #draw each pixel in Y coordinate with opacity dependant on the
          #square function of distance from the endpoint with
          #some random variance
          for y in [@size-1...cY]
            alpha = alpha + (
                (cY - @size + 1) *
                (cY - @size + 1)
              ) + Math.round(
                Math.random()*10
              )

            @setPixel bitmap, x, y, [0, 0, 0, alpha]

          cY = Math.round cY + gradientY

      null

    generateBlendMask = (p1, p2, n, p3) =>
      if p3?
        points = p1.concat p2, p3
      else
        points = p1.concat p2

      points = @midpointMisplacement steps, h, range, points

      bitmap = @context.createImageData @size, @size

      drawBlendMask bitmap, points, n

      @createBitmapObjFromBitmap bitmap, @size, @size

    midHeightLX = Math.round( @size/4 )
    midHeightY = @size - Math.round( Math.sqrt(3)*@size/4 )
    midHeightRX = Math.round( @size*3/4 )

    lbp = [0, @size-1]
    llp = [midHeightLX,midHeightY]
    rbp = [@size-1, @size-1]
    rrp = [midHeightRX,midHeightY]
    cp = [Math.round( @size/2 ), 0]

    @blendMasks.f = generateBlendMask lbp, cp, rbp, 0
    @blendMasks.lf = generateBlendMask llp, rbp, 1
    @blendMasks.fr = generateBlendMask lbp, rrp, 2
    @blendMasks.lfr = generateBlendMask llp, rrp, 3


  createBitmapObjFromBitmap: ( bitmap, width, height ) ->
    bitmapCanvas = @createBitmapCanvas width, height
    context = bitmapCanvas.getContext '2d'
    bitmapCanvas.getContext('2d').putImageData bitmap, 0, 0

    bitmapObj = new Bitmap bitmapCanvas

    $( bitmapCanvas ).remove()

    bitmapObj

  generateRoad: ( i, j, i2, j2 ) ->
    cWidth = @canvasDimensions.x
    cHeight = @canvasDimensions.y

    bitmap = @context.createImageData cWidth, cHeight

    @drawRoad bitmap, i, j, i2, j2

    bitmapObj = @createBitmapObjFromBitmap bitmap, cWidth, cHeight

    p = @getPoint i, j

    #bitmapObj.x = @distance/2
    #bitmapObj.y = @size

    @stage.addChild bitmapObj
    @stage.update()

  billinearInterpolation: (x, y) ->
    z = 0

    x1 = Math.floor(x/@heightScale)
    y1 = Math.floor(y/@heightScale)

    tile = @heightMap.tile x1, y1

    q11 = @heightMap.get_cell x1, y1
    q21 = @heightMap.get_cell x1+1, y1
    q12 = @heightMap.get_cell x1, y1+1
    q22 = @heightMap.get_cell x1+1, y1+1

    x2 = x1 + 1
    y2 = y1 + 1

    x1 = Math.floor(x1 * @heightScale)
    y1 = Math.floor(y1 * @heightScale)

    x2 = Math.floor(x2 * @heightScale)
    y2 = Math.floor(y2 * @heightScale)

    fp = (q11 / ( (x2-x1)*(y2-y1) ) ) * (x2-x) * (y2-y) +
      (q21 / ( (x2-x1)*(y2-y1) ) ) * (x-x1) * (y2-y) +
      (q12 / ( (x2-x1)*(y2-y1) ) ) * (x2-x) * (y-y1) +
      (q22 / ( (x2-x1)*(y2-y1) ) ) * (x-x1) * (y-y1)

    z = fp

    z


  midpointMisplacement: ( steps, h, range, points) ->
    oldCoords = points.slice(0)

    misplace = ([x1,y1],[x2,y2]) ->
      m = Math.round(Math.random()*range-range/2)
      [Math.round((x1+x2)/2), Math.round((y1+y2)/2)+m]

    for i in [0...steps]
      newCoords = []
      for j in [0...oldCoords.length-1]
        misplaced = misplace oldCoords[j], oldCoords[j+1]

        newCoords.push oldCoords[j]
        newCoords.push misplaced.slice(0)

      newCoords.push oldCoords[oldCoords.length-1]
      oldCoords = newCoords.slice(0)
      range = range / Math.pow(2, h)

    oldCoords

  drawRoad: ( roadImage, i, j, i2, j2 ) ->
    steps = 16

    h = 1
    range = 20

    [ht,st,lt] = @Config.colours[@getTerrain(i,j)]
    colourt = "hsl(#{ ht },#{ st }%,#{ lt }%)"

    [h,s,l] = @Config.colours.Dirt
    colourr = "hsl(#{ h },#{ s }%,#{ l }%)"

    cr = (net.brehaut.Color colourr)
    ct = (net.brehaut.Color colourt)

    rgbcr = [
      Math.round(cr.getRed()*255),
      Math.round(cr.getGreen()*255),
      Math.round(cr.getBlue()*255)
    ]

    rgbct = [
      Math.round(ct.getRed()*255),
      Math.round(ct.getGreen()*255),
      Math.round(ct.getBlue()*255)
    ]

    p1 = @getPoint i, j
    p2 = @getPoint i2, j2

    if p1.x > p2.x
      p = p1
      p1 = p2
      p2 = p

    oldCoords = [[p1.x, p1.y],[p2.x, p2.y]]

    gradientY = (p2.y-p1.y)/(p2.x-p1.x)
    gradientX = (p2.x-p1.x)/(p2.y-p1.y)

    oldCoords = @midpointMisplacement steps, h, range, oldCoords

    drawByX = gradientX > gradientY
    console.log gradientY, gradientX, drawByX

    #@drawCircle roadImage, p1.x, p1.y, 8, rgbcr, rgbct
    #@drawCircle roadImage, p2.x, p2.y, 8, rgbcr, rgbct

    for i in [0...oldCoords.length-1]
      @drawRoadSegment roadImage, rgbcr, rgbct, oldCoords[i], oldCoords[i+1], drawByX

  drawCircle: ( image, x, y, radius, [r1, g1, b1], [r2, g2, b2]) ->
    sqR = radius*radius

    mr = -1 * radius

    for i in [mr...radius]
      for j in [mr...radius]

        if sqI + sqJ <= sqR
          alpha = 0.3

          r = Math.round( r1 * (1 - alpha) + r2 * alpha)
          g = Math.round( g1 * (1 - alpha) + g2 * alpha)
          b = Math.round( b1 * (1 - alpha) + b2 * alpha)

          @setPixel image, i+x, j+y, [
            r,
            g,
            b,
            Math.round((1-alpha)*255)]

  drawRoadSegment: (roadImage, [r1,g1,b1], [r2,g2,b2], [x1,y1], [x2,y2], drawItByX ) ->
    width = 15
    cY = Math.round y1 - width/2
    cX = Math.round x1 - width/2

    gradientY = (y2-y1)/(x2-x1)
    gradientX = (x2-x1)/(y2-y1)

    x1 = Math.round x1 - width/2
    x2 = Math.round x2 - width/2
    y1 = Math.round y1 - width/2
    y2 = Math.round y2 - width/2

    drawByX = =>
      for cX in [x1..x2]

        offY = Math.round width/2

        for i in [0...width]
          alpha = (Math.pow(Math.round(Math.abs(i-offY)/width),2)*2 + Math.random())/4

          r = Math.round( r1 * (1 - alpha) + r2 * alpha)
          g = Math.round( g1 * (1 - alpha) + g2 * alpha)
          b = Math.round( b1 * (1 - alpha) + b2 * alpha)

          @setPixel roadImage, cX, cY+i, [
            r,
            g,
            b,
            Math.round((1-alpha)*255)]

        cY += gradientY

    drawByY = =>
      for cY in [y1..y2]

        offX = Math.round width/2

        for i in [0...width]

          alpha = (Math.pow(Math.round(Math.abs(i-offX)/width),2)*2 + Math.random())/4

          r = Math.round( r1 * (1 - alpha) + r2 * alpha)
          g = Math.round( g1 * (1 - alpha) + g2 * alpha)
          b = Math.round( b1 * (1 - alpha) + b2 * alpha)

          @setPixel roadImage, cX+i, cY, [
            r,
            g,
            b,
            Math.round((1-alpha)*255)]
        cX += gradientX


    if drawItByX
      drawByX()
    else
      drawByY()


    null

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

  getWaterBitmap: () ->
    if not @waterBitmap?
      bitmap = @context.createImageData @bitmapWidth, @bitmapHeight

      oldL = @Config.modifiers.s
      @Config.modifiers.s = 12

      for i in [0...@bitmapWidth]
        for j in [0...@bitmapHeight]
          @drawPoint bitmap, i, j, @Config.colours.Deepwater, 1

      @Config.modifiers.s = oldL
      @waterBitmap = @createBitmapObjFromBitmap bitmap, @bitmapWidth, @bitmapHeight

    @waterBitmap.clone()

  generateFieldBitmap: ( type, n=1 ) ->
    bitmap = @context.createImageData @bitmapWidth, @bitmapHeight

    @drawField bitmap, 0, 0, type, n

    if not @hitBitmap?
      @hitBitmap = bitmap

    bitmapCanvas = @createBitmapCanvas()
    context = bitmapCanvas.getContext '2d'
    context.clearRect 0, 0, @bitmapWidth, @bitmapHeight
    bitmapCanvas.getContext('2d').putImageData bitmap, 0, 0

    @bitmaps[type] = new Bitmap bitmapCanvas

    $( bitmapCanvas ).remove()

    bitmap

  generateShadowMap: ( terrainBitmap ) ->
    shadowMap = []
    heightMap = []

    sunVisibilityHeight = 2

    for x in [0..@canvasDimensions.x]
      shadowMap[x] = []
      for y in [0..@canvasDimensions.y]
        shadowMap[x][y] = [0] #height, shadow


    console.log "[Terrain] shadow map initialized"

    context = @stage.canvas.getContext '2d'
    terrainData = context.getImageData 0, 0, @canvasDimensions.x, @canvasDimensions.y

    #generate heights
    for x in [0...@canvasDimensions.x]
      heightMap[x] = []
      for y in [0...@canvasDimensions.y]
        [r,g,b,a] = @getPixel terrainData, x, y

        if a > 0
          heightMap[x][y] = @getHeight( x, y ) + 10


    console.log "[Terrain] height map generated"

    #generate shadows
    for x in [1...@canvasDimensions.x]
      for y in [@canvasDimensions.y-2..0]
        sourceHeight = heightMap[x][y]
        shadowHeight = heightMap[x-1][y+1]

        #if shadowHeight > sourceHeight
        #Compute the diference in height of points
        heightDiff = sourceHeight - shadowHeight

        #Divide by the difference from which the sun is not visible
        heightDiff /= sunVisibilityHeight

        if heightDiff * shadowMap[x-1][y+1] > 0
          #Save the shadow in the map
          shadowMap[x][y] =  ( heightDiff + shadowMap[x-1][y+1]/(sunVisibilityHeight*2) )
        else
          shadowMap[x][y] = heightDiff

    console.log "[Terrain] shadow map generated"

    shadowMap

  #Interpolates height in a given point starting from left bottom corner
  getHeight: (x, y) ->
    @billinearInterpolation(x,y)

  project: ( x, y, z ) ->
    x2 = Math.round(x + z/4)
    y2 = Math.round(y + z/2)

    [x2,y2]

  getShadowStrength: (height) ->
    height

  generateSurroundingWater: () ->
    n = Math.floor(@canvasDimensions.y/@bitmapHeight)
    m = Math.floor(@canvasDimensions.x/@bitmapWidth)

    for i in [0..n]
      for j in [0..m]
        b = @getWaterBitmap()

        b.y = i * @bitmapHeight
        b.x = j * @bitmapWidth

        @waterStage.addChildAt b, 0

    @waterStage.update()

  moveWater: () =>
    damping = 0.6

    cwidth  = @canvasDimensions.x
    cheight = @canvasDimensions.y

    for x in [0...cwidth]
      for y in [0...cheight]
        if x != 0 and y != 0 and x != cwidth-1 and y != cheight-1
          @waterBuffer2[x][y] = (
              @waterBuffer1[x-1][y] +
              @waterBuffer1[x+1][y] +
              @waterBuffer1[x][y+1] +
              @waterBuffer1[x][y-1]
            ) / 2 - @waterBuffer2[x][y]

          @waterBuffer2[x][y] = @waterBuffer2[x][y] * damping
        else
          @waterBuffer2[x][y] = 50
          @waterBuffer2[x][y] = 50

    @displayWaterBuffer @waterBuffer2

    @buffer = @waterBuffer1
    @waterBuffer1 = @waterBuffer2
    @waterBuffer2 = @buffer

    null

  initializeWaterBuffer: () ->
    @waterBuffer1 = []
    @waterBuffer2 = []

    cwidth  = @canvasDimensions.x
    cheight = @canvasDimensions.y

    for x in [0...cwidth]
      @waterBuffer1[x] = []
      @waterBuffer2[x] = []

      for y in [0...cheight]
        if x % 16 == 0
          @waterBuffer1[x][y] = 50
          @waterBuffer1[x][y] = 50
          @waterBuffer2[x][y] = 50
          @waterBuffer2[x][y] = 50
        else
          @waterBuffer1[x][y] = 0
          @waterBuffer1[x][y] = 0
          @waterBuffer2[x][y] = 0
          @waterBuffer2[x][y] = 0

    null

  displayWaterBuffer: ( buffer ) ->
    cwidth  = @canvasDimensions.x
    cheight = @canvasDimensions.y

    context = @waterStage.canvas.getContext '2d'
    waterData = context.getImageData 0, 0, cwidth, cheight

    [h, s, l] = @Config.colours.deepwater
    colour = "hsl(#{ h },#{ s }%,#{ l }%)"
    c = (net.brehaut.Color colour)
    r = Math.floor(c.getRed() * 255)
    g = Math.floor(c.getGreen() * 255)
    b = Math.floor(c.getBlue() * 255)

    for x in [0...cwidth]
      for y in [0...cheight]

        h = buffer[x][y]

        rm = r - h*r + 10
        gm = g - h*r + 10
        bm = b - h*r + 10

        @setPixel waterData, x, y, [
            rm,
            gm,
            bm,
            255,
          ]

    water = @createBitmapObjFromBitmap waterData, cwidth, cheight

    @waterStage.removeAllChildren()
    @waterStage.addChild water
    @waterStage.update()

    null

  applyHeightMap: () ->
    @shadowMap = @generateShadowMap()

    context = @stage.canvas.getContext '2d'
    terrainData = context.getImageData 0, 0, @canvasDimensions.x, @canvasDimensions.y

    for x in [0...@canvasDimensions.x]
      for y in [0...@canvasDimensions.y]
        [r, g, b, a] = @getPixel terrainData, x, y

        if a == 0
          continue;

        #[x2,y2] = @project x, y, @getHeight(x, y)
        [x2,y2] = [x,y]

        shadow = @shadowMap[x][y]

        @setPixel(
          terrainData,
          x2,
          y2,
          [Math.round(r - Math.round(r * shadow)),
          Math.round(g - Math.round(g * shadow)),
          Math.round(b - Math.round(b * shadow)),
          a]
        )

    terrainCanvas = @createBitmapCanvas @canvasDimensions.x, @canvasDimensions.y
    context = terrainCanvas.getContext '2d'
    terrainCanvas.getContext('2d').putImageData terrainData, 0, 0

    terrain = new Bitmap terrainCanvas

    $( terrainCanvas ).remove()

    @stage.removeAllChildren()
    @stage.addChild terrain
    @stage.x = 0
    @stage.y = 0
    @stage.update()

  getPixel: (imageData, x, y) ->
    index = (x + y * imageData.width) * 4
    d = imageData.data

    [d[index+0], d[index+1], d[index+2], d[index+3]]

  setPixel: (imageData, x, y, [r, g, b, a]) ->
    index = (x + y * imageData.width) * 4
    d = imageData.data
    d[index+0] = r
    d[index+1] = g
    d[index+2] = b
    d[index+3] = a

  getTerrain: ( i, j ) ->
    t = @events.getField( i, j ).terrain[0]
    S.Types.Terrain.Names[t-1]

  draw: ( n=1 ) ->
    @hitHexMap.visible = true

    @context = @stage.canvas.getContext '2d'

    for j in [0 ... (2*@diffRows + 1)]
      for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
        bitmap = @getFieldBitmap @getTerrain(i, j), n
        p = @getPoint i, j

        b = bitmap.clone()
        b.x = p.x
        b.y = p.y

        @stage.addChild b

    @n = n

    @loading.notify 100

    @stage.update()

    @hitHexMap.visible = false

    @events.game.map.smoothenTheTerrain(32)

    @loading.notify 100

    @applyHeightMap()

    @loading.notify 150

    @generateSurroundingWater()

    @loading.notify 50

    @stage.update()

    @readyDefer.resolve()

  t: 0

  drawField: ( image, i, j, type, n=1 ) ->
    if type is 'Water'
      return

    colour = @Config.colours[type]

    p = @getPoint i, j
    p0 = @getPoint 0, 0

    for px in [p.x-@horIncrement...p.x+@horIncrement+n] by n
      for py in [p.y-@size...p.y+@size+n] by n
        #map the point to the left top corner
        dpx = px - p0.x + @horIncrement
        dpy = py - p0.y + @size

        if i == 0 and j == 0 and @t == 0
          @t = 1

        if @hitBimap?
          [r,g,b,a] = @getPixel @hitBimap, px, py

          if a > 0
            @drawPoint image, dpx, dpy, colour, n

        else if @fieldHitTest i, j, px, py, n
          @drawPoint image, dpx, dpy, colour, n

    null

  fieldHitTest: (i, j, x, y, n=1) ->
    p = @getPoint i, j

    @hitHexMap.hitTest x-p.x, y-p.y

  #draws a single pixel with given colour - {h,s,l}
  drawPoint: ( image, x, y, initialColour, n ) ->
    hM = ((Math.random() * 100) % 2 * @Config.modifiers.h ) - @Config.modifiers.h
    sM = ((Math.random() * 100) % 2 * @Config.modifiers.s ) - @Config.modifiers.s
    lM = ((Math.random() * 100) % 2 * @Config.modifiers.l ) - @Config.modifiers.l

    [h, s, l] = initialColour

    h += hM
    s += sM
    l += lM

    colour = "hsl(#{ h },#{ s }%,#{ l }%)"
    c = (net.brehaut.Color colour)

    for i in [0...n]
      for j in [0...n]
        @setPixel image,
          x+i,
          y+j,
          [c.getRed()*255,
          c.getGreen()*255,
          c.getBlue()*255,
          255]

    null

window.S.Terrain = Terrain
