class HQBehaviour

    getType: ->
        "hq"

    requestAccept: ( signal, state ) ->
        availableRoutes = _.filter state.routing, (route, direction) ->
            route.in && route.object is signal.source
        availableRoutes.length > 0 and state.capacity + 1 <= state.signals.length

    produce: ( state ) ->
        state.field.resource.trigger 'produce'

    accept: ( signal, state, callback ) ->
        callback signal
        if signal.owner is state.owner
            state.owner.addResources signal
        else
            state.life -= signal.strength
        if state.life <= 0
            GameEngine.trigger 'player:dead', state.owner

    route: ( state ) ->

module.exports = exports = HQBehaviour
