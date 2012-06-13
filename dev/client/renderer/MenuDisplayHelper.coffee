class MenuDisplayHelper
  constructor: ( @events, @type, @menu, @i, @j, @x, @y ) ->
    @data = {}

    @build =
      '!platforminfo' : () ->
        @data.platformName = S.Types.Entities.Names[field.platform.state.type]

        @template = Handlebars.templates.platforminfo
        @html = $('<div/>')


    @build[@type].call @

  show: () ->
    field = @events.getField @i, @j

    state = {}

    if field.resource.state?
      state.resource =
        _.clone field.resource.state
      state.resource.field = {}
      state.resource.routing = {}

    #if @data.platformName == 'HQ'

    state.platform = _.clone field.platform.state
    state.platform.field = {}
    state.platform.routing = {}
    state.platform.signals = {}

    state.platform.platformName = @data.platformName

    @html.remove()
    @html = $ template( state )

    scrollX = @events.ui.scrollX
    scrollY = @events.ui.scrollY

    @html.hide()
    @html.appendToBody()


    width = @html.width()

    p = @menu.button.parent.localToGlobal @x, @y
    x = p.x - scrollX - width - 20
    y = p.y - scrollY - 40

    @html.css
      position: 'absolute'
      top: y
      left: x

    @html.show()

  hide: () ->
    @html.hide()
    @html.remove()

window.S.MenuDisplayHelper = MenuDisplayHelper
