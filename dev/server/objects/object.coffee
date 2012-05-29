class GameObject
    behaviour: {}
    state: {}

    constructor: ( behaviour, state ) ->
        _.extend @, Backbone.Events
        @behaviour = behaviour
        @state = state
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

module.exports = exports = GameObject
