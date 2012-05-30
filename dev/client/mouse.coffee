class Mouse
  constructor: ( @canvas ) ->
    self = @

    @mousedown = []
    @mouseup = []
    @mousemove = []
    @click = []

    ev_handler_click = ( e ) ->
      [x,y] = self.getXY e

      (
        if o.in x, y
          o?.click e, x, y
      ) for o in self.click

      null

    ev_handler_mouseup = ( e ) ->
      e ?= arguments[0]
      [x,y] = self.getXY e
      (
        if o.in x, y
          o?.mouseup e, x, y
      ) for o in self.mouseup

      null

    ev_handler_mousedown = ( e ) ->
      e ?= arguments[0]
      [x,y] = self.getXY e
      (
        if o.in x, y
          o?.mousedown e, x, y
      ) for o in self.mousedown

      null

    ev_handler_move = ( e ) ->
      e ?= arguments[0]
      [x,y] = self.getXY e

      (
        if o.in x, y
          o?.mousemove e, x, y
      ) for o in self.mousemove

      null

    $canvas = $ @canvas

    $canvas.on 'mousedown', ev_handler_mousedown
    $canvas.on 'mouseup', ev_handler_mouseup
    $canvas.on 'mousemove', ev_handler_move
    $canvas.on 'click', ev_handler_click




  register: ( o, e ) ->
    @[e].push o

  getXY: ( ev ) =>
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

window.MouseClass = Mouse
