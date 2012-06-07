class Terrain extends S.Drawer
  constructor: ( id, @minRow, @maxRow, map ) ->
    canvas = document.getElementById id
    @stage = new Stage canvas
    @stage.autoClear = false

    @map = []

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

    @stage.addChild @hitHexMap
    @stage.update()

  getMap: () ->

  getMapField: (i, j) ->
    @map[i] ?= []
    t = @randomTerrain()
    @map[i][j] = t
    t

  randomTerrain: () ->
    index = Math.floor((Math.random() * 100) % @typesOfTerrain.length)
    @typesOfTerrain[index]


  setPixel: (imageData, x, y, r, g, b, a) ->
    index = (x + y * imageData.width) * 4
    imageData.data[index+0] = r
    imageData.data[index+1] = g
    imageData.data[index+2] = b
    imageData.data[index+3] = a


  draw: ( n ) ->
    @hitHexMap.visible = true

    #d = @maxRow * @size * 4

    @context = @stage.canvas.getContext '2d'
    @terrain = @context.createImageData 1200, 1200

    if not n?
      n = 1

    for j in [0 ... (2*@diffRows + 1)]
      for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
        @drawField @terrain, i, j, @getMapField(i, j), n

    @stage.update()
    @context.putImageData(@terrain, 0, 0);

  drawField: ( image, i, j, type, n ) ->
    colour = @Config.colours[type]

    p = @getPoint i, j

    for px in [p.x-@size...p.x+@size+n] by n
      for py in [p.y-@size...p.y+@size+n] by n
        if @fieldHitTest i, j, px, py, n
          @drawPoint image, px, py, colour, n

    null

  fieldHitTest: (i, j, x, y, n) ->
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
          c.getRed()*255,
          c.getGreen()*255,
          c.getBlue()*255,
          255

    null

window.S.Terrain = Terrain
