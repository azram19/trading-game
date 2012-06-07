class Terrain extends S.Drawer
  constructor: ( id, @minRow, @maxRow, map ) ->
    canvas = document.getElementById id
    @stage = new Stage canvas
    @stage.autoClear = false

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
        h: 10
        s: 10
        l: 10
      size: 2

    @hitHexMap = new Shape()
    @hitHexMap.graphics
      .beginFill( "#FFF" )
      .drawPolyStar(0, 0, @Config.size, 6, 0, 90)

    @stage.addChild @hitHexMap

    super @stage, @minRow, @maxRow

  setPixel: (imageData, x, y, r, g, b, a) ->
    index = (x + @maxRow * 4) * 4
    imageData.data[index+0] = r
    imageData.data[index+1] = g
    imageData.data[index+2] = b
    imageData.data[index+3] = a


  draw: () ->
    @hitHexMap.visible = true

    d = @maxRow * @Config.size * 4

    @context = @stage.canvas.getContext '2d'
    @terrain = @context.createImageData d, d

    ###
    for j in [0 ... (2*@diffRows + 1)]
      for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
        @drawField i, j, 'water'

    console.debug @terrain
    ###

    #@terrainBitmap = new Bitmap @terrain
    #@stage.addChild @terrainBitmap
    @stage.update()

    #@context.putImageData(@terrain, 100, 100)

    imageData = @context.createImageData(10, 100);

    for i in [0...1000]
        x = Math.random() * 100 | 0;
        y = Math.random() * 100 | 0;
        r = Math.random() * 256 | 0;
        g = Math.random() * 256 | 0;
        b = Math.random() * 256 | 0;
        @setPixel(imageData, x, y, r, g, b, 100);

    @context.putImageData(imageData, 100, 100);

  drawField: ( i, j, type ) ->
    colour = @Config.colours[type]

    f = new Graphics()
    #p = @getPoint i, j
    x = i * 2
    y = j * 2

    for px in [x...x+@Config.size]
      for py in [y...y+@Config.size]
          @drawPoint px, py, colour

    null

  #draws a single pixel with given colour - {h,s,l}
  drawPoint: ( x, y, initialColour ) ->
    hM = ((Math.random() * 100) % 2 * @Config.modifiers.h ) - @Config.modifiers.h
    sM = ((Math.random() * 100) % 2 * @Config.modifiers.s ) - @Config.modifiers.s
    lM = ((Math.random() * 100) % 2 * @Config.modifiers.l ) - @Config.modifiers.l

    [h, s, l] = initialColour

    h += hM
    s += sM
    l += lM

    colour = "hsl(#{ h },#{ s }%,#{ l }%)"
    c = (net.brehaut.Color colour)

    @setPixel @terrain,
      x,
      y,
      c.getRed()*255,
      c.getGreen()*255,
      c.getBlue()*255,
      0

window.S.Terrain = Terrain
