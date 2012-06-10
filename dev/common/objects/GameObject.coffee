#node.js requirements
if require?
  _ = require 'underscore'
  Backbone = require 'backbone'
else
  _ = window._
  Backbone = window.Backbone

class GameObject
    behaviour: {}
    state: {}

    constructor: ( @behaviour, @state ) ->
        _.extend @, Backbone.Events
        @.on 'accept', @accept, @
        @.on 'produce', @produce, @

    type: ->
        @state.type

    requestAccept: ( signal ) ->
        @behaviour.requestAccept signal, @state

    actionMenu: ->
        @behaviour.actionMenu @state

    accept: ( signal, callback ) ->
        @behaviour.accept signal, @state, callback

    produce: ->
        @behaviour.produce @state

if module? and module.exports
    exports = module.exports = GameObject
else
    window.S.GameObject = GameObject
