class Terrain extends S.Drawer
  constructor: ( @events, id, @minRow, @maxRow, map ) ->
    canvas = document.getElementById id
    @stage = new Stage canvas

    @n = 1
    @map = []
    @bitmaps = {}

    @heightMap = @events.game.map.heightMap
    @shadowMap = []

    @typesOfTerrain = [
      'dirt',
      'grass',
      'water',
      'deepwater',
      'sand',
      'rocks',
      'forest'
    ]

    #colours are in hsl :P
    @Config =
      colours:
        dirt: [24, 32, 30]
        sand: [35, 40, 69]
        water: [180, 51, 38]
        deepwater: [193, 94, 28]
        rocks: [23,18,19]
        grass: [57, 42, 44]
        forest: [84, 27, 25]
      modifiers:
        h: 1
        s: 5
        l: 2
      materials:
        water:
          a: 100
          d: 100
          s: 100
          alpha: 100
        dirt: 0
        sand: 0
        deepwater: 0
        rocks: 0
        grass: 0

    @sun =
      x: 100
      y: 100
      z: 1000
      a: 100
      d: 100
      s: 100

    super @minRow, @maxRow

    @heightScale = Math.round(@canvasDimensions.x / @events.game.map.heightMapSize)

    @bitmapWidth = @distance
    @bitmapHeight = @size*2

    @blendMasks = []

    @previousHitTest = [0, 0]

    @hitHexMap = new Shape()
    @hitHexMap.graphics
      .beginFill( "#FFF" )
      .drawPolyStar(0, 0, @size+1, 6, 0, 90)
    @hitHexMap.visible = false

    @hitBitmap = null

    #offset fix
    @stage.x = -@horIncrement
    @stage.y = -@size

    @stage.addChild @hitHexMap
    @stage.update()

  createBitmapCanvas: (width = @bitmapWidth, height = @bitmapHeight) =>
    can = $( "<canvas width=#{ width } height=#{ height } />" )
        .appendTo( 'body' ).hide()

    can[0]

  getMap: () ->

  getMapField: (i, j) ->
    @map[i] ?= []
    t = @randomTerrain()
    @map[i][j] = t
    t

  randomTerrain: () ->
    index = Math.floor((Math.random() * 100) % @typesOfTerrain.length)
    @typesOfTerrain[index]

  getFieldBitmap: ( type, n=1 ) ->
    if not @bitmaps[type]? or @n != n
      @generateFieldBitmap type, n

    @bitmaps[type]

  generateRoad: ( i, j, i2, j2 ) ->
    bitmap = @context.createImageData @canvasDimensions.x, @canvasDimensions.y

    @drawRoad bitmap, i, j, i2, j2

    bitmapCanvas = @createBitmapCanvas @canvasDimensions.x, @canvasDimensions.y
    context = bitmapCanvas.getContext '2d'
    #context.clearRect 0, 0, @bitmapWidth*3, @bitmapHeight*3
    bitmapCanvas.getContext('2d').putImageData bitmap, 0, 0

    bitmapObj = new Bitmap bitmapCanvas

    $( bitmapCanvas ).remove()

    p = @getPoint i, j

    bitmapObj.x = @distance/2
    bitmapObj.y = @size

    @stage.addChild bitmapObj
    @stage.update()
    window.road = bitmapObj

  drawRoad: ( roadImage, i, j, i2, j2 ) ->
    steps = 10

    h = 0.9
    range = 40

    [ht,st,lt] = @Config.colours[@getTerrain(i,j)]
    colourt = "hsl(#{ ht },#{ st }%,#{ lt }%)"

    [h,s,l] = @Config.colours.dirt
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

    for i in [0...oldCoords.length-1]
      @drawRoadSegment roadImage, rgbcr, rgbct, oldCoords[i], oldCoords[i+1]

  drawRoadSegment: (roadImage, [r1,g1,b1], [r2,g2,b2], [x1,y1], [x2,y2]) ->
    minWidth = 10
    maxWidth = 16
    oldWidth = Math.round((minWidth + maxWidth)/2)
    newWidth = oldWidth
    chance = 0.3
    cY = y1
    gradientY = (y2-y1)/(x2-x1)

    for cX in [x1..x2]
      v = Math.random()

      if v < chance
        if v > chance/2 and oldWidth < maxWidth
          newWidth++
        else if oldWidth > minWidth
          newWidth--

      offY = Math.round newWidth/2

      for i in [0...newWidth]
        alpha = (Math.pow(Math.round(Math.abs(i-offY)/newWidth),2)*2 + Math.random())/4

        r = Math.round( r1 * (1 - alpha) + r2 * alpha)
        g = Math.round( g1 * (1 - alpha) + g2 * alpha)
        b = Math.round( b1 * (1 - alpha) + b2 * alpha)

        @setPixel roadImage, cX, Math.round(cY+i-offY), [
          r,
          g,
          b,
          Math.round((1-alpha)*255)]

      oldWidth = newWidth
      cY += gradientY

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

      for i in [0...@bitmapWidth]
        for j in [0...@bitmapHeight]
          @drawPoint bitmap, i, j, @Config.colours.deepwater, 1

      bitmapCanvas = @createBitmapCanvas()
      context = bitmapCanvas.getContext '2d'
      context.clearRect 0, 0, @bitmapWidth, @bitmapHeight
      bitmapCanvas.getContext('2d').putImageData bitmap, 0, 0

      @waterBitmap = new Bitmap bitmapCanvas

      $( bitmapCanvas ).remove()

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

  generateShadowMap: () ->
    shadowMap = []

    for x in [0...@canvasDimensions.x]
      shadowMap[x] = []
      for y in [0...@canvasDimensions.y]
        shadowMap[x][y] = 0

    for i in [0...28] by 2
      for j in [0...28] by 2
        @generateShadowedTile i, j, shadowMap

    shadowMap

  generateShadowedTile: (i, j, shadowMap) ->
    tileNW = @heightMap.tile i, j
    @generateShadowedSubTile i, j, tileNW, false, shadowMap
    @generateShadowedSubTile i, j, tileNW, true, shadowMap

    tileNE = @heightMap.tile i+1, j
    @generateShadowedSubTile i+1, j, tileNE, false, shadowMap
    @generateShadowedSubTile i+1, j, tileNE, true, shadowMap

    tileSW = @heightMap.tile i, j+1
    @generateShadowedSubTile i, j+1, tileSW, false, shadowMap
    @generateShadowedSubTile i, j+1, tileSW, true, shadowMap

    tileSE = @heightMap.tile i+1, j+1
    @generateShadowedSubTile i+1, j+1, tileSE, false, shadowMap
    @generateShadowedSubTile i+1, j+1, tileSE, true, shadowMap

    shadowMap

  billinearInterpolation: (x, y) ->
    z = 0

    x1 = Math.round(x/@heightScale)
    y1 = Math.round(y/@heightScale)

    tile = @heightMap.tile x1, y1

    q11 = tile.sw
    q21 = tile.se
    q12 = tile.nw
    q22 = tile.ne

    x2 = x1 + 1
    y2 = y1 + 1

    x1 = Math.round(x1 * @heightScale)
    y1 = Math.round(y1 * @heightScale)

    x2 = Math.round(x2 * @heightScale)
    y2 = Math.round(y2 * @heightScale)

    fp = (q11 / ( (x2-x1)*(y2-y1) ) ) * (x2-x) * (y2-y) +
      (q21 / ( (x2-x1)*(y2-y1) ) ) * (x-x1) * (y2-y) +
      (q12 / ( (x2-x1)*(y2-y1) ) ) * (x2-x) * (y-y1) +
      (q22 / ( (x2-x1)*(y2-y1) ) ) * (x-x1) * (y-y1)

    console.log x1, x, x2, y1, y, y2, q11, q21, q12, q22

    z = fp

    z

  #we may either want to generate southern or northern triangle
  generateShadowedSubTile: (i, j, tile, north, shadowMap) ->
    height = @heightScale
    width = @heightScale

    xStart = i * width
    yStart = j * height

    if north
      start = tile.nw

      for x in [xStart...xStart+width]
        for y in [yStart..yStart+height-x+xStart]
          h = tile.sw-(tile.nw + tile.ne)/2
          shadowMap[x][y] =  h*2
          start = h

    else
      start = tile.sw

      for x in [xStart...xStart+width]
        for y in [yStart+height-x+xStart...yStart+height]
          h = (tile.sw + tile.se)/2 - tile.ne
          shadowMap[x][y] = h*2

          start = h

    shadowMap

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

    for i in [0...n]
      for j in [0...m]
        b = @getWaterBitmap()

        b.y = i * @bitmapHeight
        b.x = j * @bitmapWidth

        @stage.addChild b

    @stage.update()

  applyHeightMap: () ->
    @shadowMap = @generateShadowMap()

    console.log "Shadow map generated"
    context = @stage.canvas.getContext '2d'
    terrainData = context.getImageData 0, 0, @canvasDimensions.x, @canvasDimensions.y

    for x in [0...@canvasDimensions.x]
      for y in [0...@canvasDimensions.y]
        [r, g, b, a] = @getPixel terrainData, x, y

        if a == 0
          continue;

        #shadow = @shadowMap[x][y]

        #[x2,y2] = @project x, y, 1
        [x2,y2] = [x,y]

        @setPixel(
          terrainData,
          x2,
          y2,
          [Math.round(r+@shadowMap[x][y]),
          Math.round(g+@shadowMap[x][y]),
          Math.round(b+@shadowMap[x][y]),
          a]
        )
        ###
        @setPixel(
          terrainData,
          x2,
          y2,
          [r,g,b,a]
        )
        ###

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
    imageData.data[index+0] = r
    imageData.data[index+1] = g
    imageData.data[index+2] = b
    imageData.data[index+3] = a

  getTerrain: ( i, j ) ->
    t = @events.getField( i, j ).terrain[0]
    S.Types.Terrain.Names[t-1]

  draw: ( n=1 ) ->
    @hitHexMap.visible = true

    @context = @stage.canvas.getContext '2d'

    @generateSurroundingWater()

    for j in [0 ... (2*@diffRows + 1)]
      for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
        bitmap = @getFieldBitmap @getTerrain(i, j), n
        p = @getPoint i, j

        b = bitmap.clone()
        b.x = p.x
        b.y = p.y

        @stage.addChild b

    @n = n

    @hitHexMap.visible = false

    @stage.update()


  t: 0

  drawField: ( image, i, j, type, n=1 ) ->
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
