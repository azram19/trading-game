#node.js requirements
if require?
  _ = require 'underscore'
  Backbone = require 'backbone'

class User extends Backbone.Model
  initialize: () ->

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
  exports = module.exports = User
else
  root['User'] = User
