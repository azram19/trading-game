class Terrain extends S.Drawer
  constructor: ( id, @minRow, @maxRow, map ) ->
    canvas = document.getElementById id
    @stage = new Stage canvas

    @n = 1
    @map = []
    @bitmaps = {}

    @heightMap = {}
    @shadowMap = []

    @typesOfTerrain = [
      'dirt',
      'grass',
      'water',
      'deepwater',
      'sand',
      'stone',
      'forest'
    ]

    @Config =
      colours:
        dirt: [24, 32, 30]
        sand: [35, 40, 69]
        water: [180, 51, 38]
        deepwater: [193, 94, 28]
        stone: [30, 13, 50]
        grass: [57, 42, 44]
        forest: [84, 27, 25]
      modifiers:
        h: 1
        s: 5
        l: 2

    @materials =
      water:
        a: 100
        d: 100
        s: 100
        alpha: 100

    @sun =
      x: 100
      y: 100
      z: 1000
      a: 100
      d: 100
      s: 100

    super @minRow, @maxRow

    @heightScale = Math.floor(@canvasDimensions.x / 128)

    @bitmapWidth = @distance
    @bitmapHeight = @size*2

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
    #index = Math.floor((Math.random() * 100) % @typesOfTerrain.length)
    #@typesOfTerrain[index]
    'grass'

  getFieldBitmap: ( type, n=1 ) ->
    if not @bitmaps[type]? or @n != n
      @generateFieldBitmap type, n

    @bitmaps[type]

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

    for i in [0..120] by 2
      for j in [0..120] by 2
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

    x1 = Math.floor(x/@heightScale)
    y1 = Math.floor(y/@heightScale)

    tile = @heightMap.tile x1, y1

    q11 = tile.sw
    q21 = tile.se
    q12 = tile.nw
    q22 = tile.ne

    x2 = x1 + 1
    y2 = y1 + 1

    x1 = Math.ceil(x1 * @heightScale)
    y1 = Math.ceil(y1 * @heightScale)

    x2 = Math.ceil(x2 * @heightScale)
    y2 = Math.ceil(y2 * @heightScale)

    fp = (q11 / ( (x2-x1)*(y2-y1) ) ) * (x2-x) * (y2-y) +
      (q21 / ( (x2-x1)*(y2-y1) ) ) * (x-x1) * (y2-y) +
      (q12 / ( (x2-x1)*(y2-y1) ) ) * (x2-x) * (y-y1) +
      (q22 / ( (x2-x1)*(y2-y1) ) ) * (x-x1) * (y-y1)

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
          h = @getHeight x, y
          shadowMap[x][y] =  h - 100
          start = h

    else
      start = tile.sw

      for x in [xStart...xStart+width]
        for y in [yStart+height-x+xStart...yStart+height]
          h = @getHeight x, y
          shadowMap[x][y] = h - 100
          start = h

    shadowMap

  getHeight: (x, y) ->
    @billinearInterpolation(x,y)

  scaleHeight: (h) ->
    if h?
      Math.floor (h - 100) * 0.4
    else
      null

  project: ( x, y, z ) ->
    x2 = Math.round(x + z/4)
    y2 = Math.round(y + z/2)

    [x2,y2]

  getShadowStrength: (height) ->
    height

  generateHeightMap: () ->
    @heightMap = new S.HeightMap 129, 129
    @heightMap.run()

  generateMap: () ->

  generateSurroundingWater: () ->
    context = @stage.canvas.getContext '2d'
    terrainData = context.getImageData 0, 0, @canvasDimensions.x, @canvasDimensions.y

    for x in [0...@canvasDimensions.x]
      for y in [0...@canvasDimensions.y]
        [r, g, b, a] = @getPixel terrainData, x, y

        if a == 0
          @drawPoint terrainData, x, y, @Config.colours.deepwater, 1

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

  applyHeightMap: () ->
    @generateHeightMap()
    console.log "Height map generated"
    @shadowMap = @generateShadowMap()

    console.log "Shadow map generated"
    context = @stage.canvas.getContext '2d'
    terrainData = context.getImageData 0, 0, @canvasDimensions.x, @canvasDimensions.y

    for x in [0...@canvasDimensions.x]
      for y in [0...@canvasDimensions.y]
        [r, g, b, a] = @getPixel terrainData, x, y

        shadow = @shadowMap[x][y]

        [x2,y2] = @project x, y, (@getHeight x, y)
        #[x2,y2] = [x,y]

        @setPixel(
          terrainData,
          x2,
          y2,
          [Math.round(r+@shadowMap[x][y]),
          Math.round(g+@shadowMap[x][y]),
          Math.round(b+@shadowMap[x][y]),
          a]
        )


    terrainCanvas = @createBitmapCanvas @canvasDimensions.x, @canvasDimensions.y
    context = terrainCanvas.getContext '2d'
    terrainCanvas.getContext('2d').putImageData terrainData, 0, 0

    console.debug terrainData

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


  draw: ( n=1 ) ->
    @hitHexMap.visible = true

    @context = @stage.canvas.getContext '2d'

    for j in [0 ... (2*@diffRows + 1)]
      for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
        bitmap = @getFieldBitmap @randomTerrain(), n
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
          dpx = px - p0.x + @horIncrement
          dpy = py - p0.y + @size
          console.debug [p,p0,px,py,dpx,dpy]
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
