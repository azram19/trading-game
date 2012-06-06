class UI extends Drawer
  constructor: ( @stage, @minRow, @maxRow ) ->
    super @stage, @minRow, @maxRow

    _.extend @, Backbone.Events

    @on "fieldClick", @handleClickOnField

    @menus = []

  initializeMenus: () ->
    for j in [0 ... (2*@diffRows + 1)]
      @menus[j] = {}
      for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
        @menus[j][i] = {}

    for j in [0 ... (2*@diffRows + 1)]
      @menus[j] = {}
      for i in [0 ... @maxRow - Math.abs(@diffRows - j)]
        @menus[j][i] = @createMenu i, j

    null

  createMenu: (i, j) ->
    p = @getPoint i, j

    rd5 = '<p>"No more, Queequeg," said I, shuddering; "that will do;" for I knew the inferences without his further hinting them. I had seen a sailor who had visited that very island, and he told me that it was the custom, when a great battle had been gained there, to barbecue all the slain in the yard or garden of the victor; and then, one by one, they were placed in great wooden trenchers, and garnished round like a pilau, with breadfruit and cocoanuts; and with some parsley in their mouths, were sent round with the victors compliments to all his friends, just as though these presents were so many Christmas turkeys.</p>'

    console.debug [i,j,p.x,p.y]

    menu = new radialMenu null, @stage, "", "", p.x, p.y, () ->
      console.log 'Click hehe'

    r2 = new radialMenu null, @stage, "kotek", rd5
    r3 = new radialMenu null, @stage, "malpka", rd5

    menu.addChild r2
    menu.addChild r3

    menu

  handleClickOnField: ( i, j ) =>
    (menu?.hide() for menu in menuI) for menuI in @menus

    @menus[j][i].click()

  render: (i,j) ->
    menu = @menus[j][i]
    menu.drawIt()
    menu.show()

    console.log "Rendering finished"

window.UIClass = UI

$ ->
  canvas = document.getElementById "UI"
  if canvas?
    stage = new Stage canvas
    window.UI = UI = new UIClass stage, 8, 15
    UI.initializeMenus()
    UI.render 0, 0
    UI.render 0, 1
    UI.render 1, 0
    UI.render 1, 1
    UI.render 2, 1

