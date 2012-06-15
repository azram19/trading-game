#node.js requirements
S = {}
if require?
  _ = require 'underscore'
  S.Types = require '../config/Types'
else
  S.Types = window.S.Types

class Player

  constructor: ->
    @resources = {}

  addResource: ( s ) ->
    @resources[S.Types.Resources.Names[s.type-6]] ?= 0
    @resources[S.Types.Resources.Names[s.type-6]] += s.strength

  spendResources: ( t, x ) ->
    if @resources[t] > x
      @resources[t] -= x
      true
    else
      false

if module? and module.exports
  exports = module.exports = Player
else
  window.S.Player = Player
