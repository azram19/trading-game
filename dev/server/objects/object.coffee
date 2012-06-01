#node.js requirements
if require?
  _ = require 'underscore'
  Backbone = require 'backbone'

class GameObject
    behaviour: {}
    state: {}

    constructor: ( @behaviour, @state ) ->
        _.extend @, Backbone.Events
        @.on 'accept', @accept, @
        @.on 'produce', @produce, @

    type: ->
        @behaviour.getType()

    requestAccept: ( signal, state ) ->
        @behaviour.requestAccept source, @state

    accept: ( signal, callback ) ->
        @behaviour.accept signal, @state, callback

    produce: ->
        @behaviour.produce @state

if module? and module.exports
    exports = module.exports = GameObject
else
    root['GameObject'] = GameObject
