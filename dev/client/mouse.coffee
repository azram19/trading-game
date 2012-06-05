class Mouse
  constructor: ( @canvas, @width, @height ) ->
    self = @

    #all items in the tree
    @items = []

    #list of objects recently affected by 'in'
    @oldIn = []

    #quad tree of the items
    @tree = new QuadTree
      x:0
      y:0
      width: @width
      height:@height,
      false,
      4,
      4

    #returns canvas absolute coordinates
    getXY = ( ev ) =>
      totalOffsetX = 0
      totalOffsetY = 0
      canvasX = 0
      canvasY = 0
      currentElement = @canvas

      totalOffsetX += currentElement.offsetLeft
      totalOffsetY += currentElement.offsetTop

      (
          totalOffsetX += currentElement.offsetLeft
          totalOffsetY += currentElement.offsetTop
      ) while currentElement = currentElement.offsetParent

      canvasX = ev.pageX - totalOffsetX;
      canvasY = ev.pageY - totalOffsetY;

      [canvasX, canvasY]

    #event handler
    ev_handler = ( e ) =>
      #retrieves real coordinates of an event
      e ?= arguments[0]
      [x,y] = getXY e

      #retrieves objects in the area of an event
      handlersObjs = @tree.retrieve
        x: x
        y: y
        width: 2
        height: 2

      inBoundaries = ( o ) ->
        bs = o.b.boundaries
        bs.x < x and bs.y < y and bs.x + bs.width > x and bs.y + bs.height > y

      #sorts elements by priority and then selects those with the highest priority
      handlersObjs = _.chain( handlersObjs )
        .filter( inBoundaries )
        .value()

      if e.type is 'mousemove'
        oldInIds = _.pluck @oldIn, 'id'
        curInIds = _.pluck handlersObjs, 'id'

        outIds = _.difference oldInIds, curInIds
        inIds = _.difference curInIds, oldInIds

        outObjs = _.filter @oldIn, ( ob ) ->
          ob.id in outIds

        inObjs = _.filter handlersObjs, ( ob ) ->
          ob.id in inIds

        @oldIn = handlersObjs

        if outObjs.length > 0
          ev_handler_mouseout e, outObjs

        if inObjs.length > 0
          ev_handler_mousein e, inObjs

      handlersObjs = _.chain( handlersObjs )
        .filter( ( o ) -> e.type in o.es )
        .sortBy( ( o ) -> -o.p )
        .filter( (o, i, l) -> o.p == (_.first l).p )
        .value()

      #executes a callback
      (
        if o.target?
          e.target = o.target

        o.f e, x, y
      ) for o in handlersObjs

      null

    #handler for abstract event out
    ev_handler_mouseout = ( e, objs ) =>
      [x,y] = getXY e

      e.type = 'mouseout'

      objs = _.chain( objs )
        .filter( ( o ) -> e.type in o.es )
        .sortBy( ( o ) -> -o.p )
        .filter( (o, i, l) -> o.p == (_.first l).p )
        .value()

      #executes a callback
      (
        if o.target?
          e.target = o.target

        o.f e, x, y
      ) for o in objs

    #handler for abstract event in
    ev_handler_mousein = ( e, objs ) =>
      [x,y] = getXY e

      e.type = 'mousein'

      objs = _.chain( objs )
        .filter( ( o ) -> e.type in o.es )
        .sortBy( ( o ) -> -o.p )
        .filter( (o, i, l) -> o.p == (_.first l).p )
        .value()

      #executes a callback
      (
        if o.target?
          e.target = o.target

        o.f e, x, y
      ) for o in objs

    $canvas = $ @canvas

    $canvas.on 'mousedown', ev_handler
    $canvas.on 'mouseup', ev_handler
    $canvas.on 'mousemove', ev_handler
    $canvas.on 'click', ev_handler

    Ticker.addListener @, true

  ###
  registers a callback for when the event happened within the boundaries

  arguments:
  b - reference to an object with boundaries object {x,y,width,height}
  f - ( e, x, y ) ->
  es - [events]
  p - priority

  return:
  unique id for the element, neede to deregister an object
  ###
  register: ( b, f, es, p) ->
    id = _.uniqueId 'object_'

    p ?= 0

    o = {}
    o.b = b #reference
    o.f = f
    o.es = es
    o.p = p
    o.id = id

    if b.target?
      o.target = b.target

    _.extend o, b.boundaries #values

    @tree.insert o
    @items.push o

    id

  deregister: ( id ) ->
    @items = _.reject @items, ( o ) -> o.id == id

  #updates the quad tree in case coordinates, boundaries or elements changed
  tick: =>
    @tree.clear()

    items = _.map @items, ( i ) ->
      _.extend i, i.b.boundaries

    @tree.insert items

window.MouseClass = Mouse
