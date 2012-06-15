class MenuDisplayHelper
  constructor: ( @events, @type, @menu, @i, @j, @x, @y ) ->
    @data = {}

    @build =
      'platforminfo' : () ->
        field = @events.getField @i, @j
        platformSt = field.platform.state

        @data.platformName = S.Types.Entities.Names[platformSt.type]


        @data.resources = []

        if field.resource.state? and field.resource.state.type? and platformSt.type != S.Types.Entities.Platforms.HQ
          resource = field.resource.state
          res =
              size: Math.floor resource.life
              extraction: Math.round( (resource.extraction * 1000) / resource.delay )
              name: S.Types.Resources.Names[resource.type-6]

          @data.resources.push res
        else if platformSt.type == S.Types.Entities.Platforms.HQ
          res =
              size: "Infinity"
              extraction: Math.round( (platformSt.extraction * 1000) / platformSt.delay )
              name: "Food"

          @data.resources.push res

          res =
              size: "Infinity"
              extraction: Math.round( (platformSt.extraction * 1000) / platformSt.delay )
              name: "Gold"

          @data.resources.push res

        @data.life = platformSt.life
        @data.space = platformSt.signals
        @data.maxSpace = platformSt.capacity

        @data.platform = @data

        @template = Handlebars.templates.platforminfo
        @html = $('<div/>')


    if @build[@type]?
      @build[@type].call @

  show: () ->
    @html.remove()
    @html = $ @template @data

    scrollX = @events.ui.scrollX
    scrollY = @events.ui.scrollY

    @html.hide()
    @html.appendTo '#canvasWrapper .scrollIt'


    width = @html.width()
    height = @html.height()

    p = @menu.button.parent.localToGlobal @x, @y
    x = p.x - width - 60
    y = p.y - height/2

    @html.css
      position: 'absolute'
      top: y
      left: x
      'z-index': 500

    @html.show()

  hide: () ->
    @html.hide()
    @html.remove()

window.S.MenuDisplayHelper = MenuDisplayHelper
