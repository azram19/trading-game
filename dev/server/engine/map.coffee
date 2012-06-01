class Map
  fields: {} #level 0 on the map, resources and shit
  channels: {} #channels connecting fields

  constructor: ( widthMin, widthMax ) ->
    initializeField = ( x, y ) ->
      field = new Field()
      

    (
      initializeField x, y for x in [0...(widthMin+y)]
    ) for y in [0..(widthMax - widthMin)]

    (
      initializeField x, y for x in [0...(widthMin+y)]
    ) for y in [(widthMax - widthMin )..0]

 

  addField: ( field, x , y ) ->
    @fields[x] ?= {}
    @fields[x][y] = field

  #k - direction [0..6] clockwise from the top
  addChannel: ( channel, x, y, k ) ->
    @channels[x] ?= {}
    @channels[x][y] ?= {}
    @channels[x][y][k] = channel

  getField: ( x, y ) -> 
    if fields[x]?
      return fields[x][y]

    return null