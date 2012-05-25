class PlatformBehaviour
    produce: ( state ) ->

    accept: ( signal, state, callback ) ->
        if state.signals.length is state.capacity
            callback signal
        else
            state.signals.push signal
            _.delay @route, state.delay, state

    route: ( state ) ->

        availableRoutes = _.map state.routing, (route) ->
            route.object.trigger 'accept', new Signal(1, 1),

        _.each state.signals, (signal) ->
            _.each state.routing (route) ->
                route.object.trigger 'accept', new Signal(signal, route.amount)
        
