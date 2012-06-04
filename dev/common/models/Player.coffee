#node.js requirements
if require?
  _ = require 'underscore'

class Player

  constructor: ->
    @resources = {}

  addResource: ( s ) ->
    @resources[s.type] ?= 0
    @resources[s.type] += s.strength

  spendResources: ( t, x ) ->
    if @resources[t] > x
      @resources[t] -= x
      true
    else
      false

if module? and module.exports
  exports = module.exports = Player
else
  window['Player'] = Player
