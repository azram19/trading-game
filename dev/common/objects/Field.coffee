class Field

    constructor: (x, y) ->
      @xy = [x,y]
      @channels = {}
      @platform = {}
      @resource = {}
      @terrain = []
      @owner = {}

if module? and module.exports
  exports = module.exports = Field
else
  window.S.Field = Field
