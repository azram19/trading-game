class Terrain extends S.Drawer
  constructor: ( @events, id, @minRow, @maxRow, map ) ->
    canvas = document.getElementById id
    @stage = new Stage canvas

    @n = 1
    @bitmaps = {}

    @heightMap = @events.game.map.heightMap
    @shadowMap = []
    @blendMasks = {}

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

    super @minRow, @maxRow

    @heightScale = Math.round(@canvasDimensions.x / @events.game.map.heightMapSize)

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

  randomTerrain: () ->
    index = Math.floor((Math.random() * 100) % @typesOfTerrain.length)
    @typesOfTerrain[index]

  getFieldBitmap: ( type, n=1 ) ->
    if not @bitmaps[type]? or @n != n
      @generateFieldBitmap type, n

    @bitmaps[type]

  applyBlendMasks: () ->
    #blendCanvas
    #terrain 

    applyBlendMask: ( mask, x, y, k, width = @size, height = @size ) ->
      mask.regX = Math.round width/2
      mask.regY = Math.round @size - @horIncrement
      mask.rotation = Math.PI/2 + Math.PI/3 * k



  generateBlendMasks: () ->
    steps = 8
    h = 0.6
    range = 8

    drawBlendMask = ( bitmap, points, n ) ->
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

    generateBlendMask = (p1, p2, n, p3) ->
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
    @blendMasks.rf = generateBlendMask lbp, rrp, 2
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

    bitmapObj.x = @distance/2
    bitmapObj.y = @size

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

    oldCoords = @midpointMisplacement steps, h, range, oldCoords

    for i in [0...oldCoords.length-1]
      @drawRoadSegment roadImage, rgbcr, rgbct, oldCoords[i], oldCoords[i+1]

  drawRoadSegment: (roadImage, [r1,g1,b1], [r2,g2,b2], [x1,y1], [x2,y2]) ->
    minWidth = 10
    maxWidth = 16
    oldWidth = Math.round((minWidth + maxWidth)/2)
    newWidth = oldWidth
    chance = 0.3
    cY = y1
    cX = x1

    gradientY = (y2-y1)/(x2-x1)
    gradientX = (x2-x1)/(y2-y1)

    drawByX = =>
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

    drawByY = =>
      for cY in [y1..y2]
        v = Math.random()

        if v < chance
          if v > chance/2 and oldWidth < maxWidth
            newWidth++
          else if oldWidth > minWidth
            newWidth--

        offX = Math.round newWidth/2

        for i in [0...newWidth]
          alpha = (Math.pow(Math.round(Math.abs(i-offX)/newWidth),2)*2 + Math.random())/4

          r = Math.round( r1 * (1 - alpha) + r2 * alpha)
          g = Math.round( g1 * (1 - alpha) + g2 * alpha)
          b = Math.round( b1 * (1 - alpha) + b2 * alpha)

          @setPixel roadImage, Math.round(cX+i-offX), cY, [
            r,
            g,
            b,
            Math.round((1-alpha)*255)]

        oldWidth = newWidth
        cX += gradientX

    if gradientX < gradientY
      drawByY()
    else 
      drawByX()

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

    sunVisibilityHeight = 0.5

    for x in [0..@canvasDimensions.x]
      shadowMap[x] = []
      for y in [0..@canvasDimensions.y]
        ###
        if x % 48 == 0 and y % 48 == 0
          shadowMap[x][y] = [@heightMap.get_cell( Math.floor(x/48), Math.floor(y/48) ), 0]
        else if x > 0 and y > 0
          shadowMap[x][y] = shadowMap[x-1][y-1]
        else if x > 0
          shadowMap[x][y] = shadowMap[x-1][y]
        else if y > 0
          shadowMap[x][y] = shadowMap[x][y-1]
        else 
        ###
        shadowMap[x][y] = [0,0] #height, shadow
        
        
    console.log "[Terrain] shadow map initialized"

    #generate heights
    for x in [0...@canvasDimensions.x-1]
      for y in [0...@canvasDimensions.y-1]
        shadowMap[x][y] = [@getHeight( x, y ), 0]

    for x in [0...@canvasDimensions.x-1]
      for y in [1...@canvasDimensions.y-1]
        [height1, shadow1] = shadowMap[x][y]
        [height2, shadow2] = shadowMap[x][y-1]
        shadowMap[x][y] = [(height1+height2)/2,shadow1]

    console.log "[Terrain] height map generated"

    #generate shadows
    for x in [1...@canvasDimensions.x]
      for y in [@canvasDimensions.y-2..0]
        [sourceHeight, s] = shadowMap[x][y]
        [shadowHeight, s2] = shadowMap[x-1][y+1]

        #if shadowHeight > sourceHeight
        #Compute the diference in height of points
        heightDiff = shadowHeight - sourceHeight

        #Divide by the difference from which the sun is not visible
        heightDiff /= sunVisibilityHeight

        #Cap the difference to 1
        #if heightDiff > 1
        # heightDiff = 1

        #Save the shadow in the map
        shadowMap[x][y] = [sourceHeight, heightDiff]

    console.log "[Terrain] shadow map generated"

    shadowMap

  ###
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
  ###

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

  #we may either want to generate southern or northern triangle
  generateShadowedSubTile: (i, j, tile, north, shadowMap) ->
    height = @heightScale
    width = @heightScale

    xStart = i * width
    yStart = j * height

    if north
      for x in [xStart...xStart+width]
        for y in [yStart..yStart+height-x+xStart]
          h = tile.sw-(tile.nw + tile.ne)/2
          shadowMap[x][y] =  [h, h*2]

    else
      for x in [xStart...xStart+width]
        for y in [yStart+height-x+xStart...yStart+height]
          h = (tile.sw + tile.se)/2 - tile.ne
          shadowMap[x][y] = [h, h*2]

    shadowMap

  #Interpolates height in a given point starting from left bottom corner
  getHeight: (x, y) ->
    return @billinearInterpolation(x,y)
    
    xPos = Math.floor x/@heightScale
    yPos = Math.floor y/@heightScale

    z0 = @heightMap.get_cell xPos, yPos
    z1 = @heightMap.get_cell xPos + 1, yPos
    z2 = @heightMap.get_cell xPos, yPos - 1
    z3 = @heightMap.get_cell xPos + 1, yPos - 1

    height = 0
    
    sqX = (x / @heightScale) - xPos
    sqY = (y / @heightScale) - yPos

    if sqX + sqY < 1
      height = z0
      height += (z1-z0) * sqX
      height += (z2-z0) * sqY
    else
      height = z3
      height += (z1 - z3) * (1.0 - sqY)
      height += (z2 - z3) * (1.0 - sqX)

    height

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

        [height, shadow] = @shadowMap[x][y] 

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
