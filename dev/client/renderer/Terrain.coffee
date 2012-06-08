class Terrain extends S.Drawer
  constructor: ( id, @minRow, @maxRow, map ) ->
    canvas = document.getElementById id
    @stage = new Stage canvas

    @n = 1
    @map = []
    @bitmaps = {}

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

    super @stage, @minRow, @maxRow

    @previousHitTest = [0, 0]

    @hitHexMap = new Shape()
    @hitHexMap.graphics
      .beginFill( "#FFF" )
      .drawPolyStar(0, 0, @size+1, 6, 0, 90)
    @hitHexMap.visible = false

    #offset fix
    @stage.x = -82
    @stage.y = -101

    @stage.addChild @hitHexMap
    @stage.update()

  createBitmapCanvas: (width = 200, height = 200) =>
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

  generateFieldBitmap: ( type, n=1 ) ->
    bitmap = @context.createImageData 200, 200

    @drawField bitmap, 0, 0, type, n

    bitmapCanvas = @createBitmapCanvas()
    context = bitmapCanvas.getContext '2d'
    context.clearRect 0, 0, 200, 200
    bitmapCanvas.getContext('2d').putImageData bitmap, 0, 0

    @bitmaps[type] = new Bitmap bitmapCanvas

    $( bitmapCanvas ).remove()

    bitmap

  generateHeightMap: () ->
    @heightMap = new HeightMap 1024, 1024
    @heightMap.run()

  applyHeightMap: () ->
    #@generateHeightMap()
    console.log "height map generated"
    context = @stage.canvas.getContext '2d'
    terrainData = context.getImageData 0, 0, 1024, 1024

    for x in [0...1024]
      for y in [0...1024]
        [r, g, b, a] = @getPixel terrainData, x, y
        #height = @heightMap.get_cell x, y
        c = net.brehaut.Color(
          red: r,
          green: g,
          blue: b,
          alpha: a
        ).darkenByAmount(
         0.1
        )

        @setPixel(
          terrainData,
          x,
          y,
          [c.getRed(),
          c.getGreen(),
          c.getBlue(),
          a]
        )


    terrainCanvas = @createBitmapCanvas 1024, 1024
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

    #d = @maxRow * @size * 4

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


  drawField: ( image, i, j, type, n=1 ) ->
    colour = @Config.colours[type]

    p = @getPoint i, j

    for px in [p.x-@size...p.x+@size+n] by n
      for py in [p.y-@size...p.y+@size+n] by n
        if @fieldHitTest i, j, px, py, n
          @drawPoint image, px, py, colour, n

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
