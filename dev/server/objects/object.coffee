class GameObject
    behaviour: {}
    state: {}

    constructor: ( behaviour, state ) ->
        _.extend @, Backbone.Events
        @behaviour = behaviour
        @state = state
        @.on 'accept', @accept, @
        @.on 'route', @route, @
        @.on 'produce', @produce, @

    type: ->
        @behaviour.getType()

    route: ->
       @behaviour.route @state

    accept: ( signal, callback ) ->
        @behaviour.accept signal, @state, callback

    produce: ->
        @behaviour.produce @state
