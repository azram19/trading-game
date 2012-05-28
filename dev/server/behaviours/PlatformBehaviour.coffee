class PlatformBehaviour

    getType: ->
        "platform"

    produce: ( state ) ->
        production = ->
            state.signals.push new Signal(state.resourceType.extract()), 1
            @route state

        setInterval production, state.productionDelay

    accept: ( signal, state, callback ) ->
        if state.signals.length is state.capacity
            callback signal
        else
            _.delay state.signals.push, state.delay, signal
            @route state

    route: ( state ) ->

        availableRoutes = _.map state.routing, (route) ->
            route.object.trigger 'accept', new Signal(1, 1),

        _.each state.signals, (signal) ->
            _.each state.routing (route) ->
                route.object.trigger 'accept', new Signal(signal, route.amount)
