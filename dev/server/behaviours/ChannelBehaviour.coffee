class ChannelBehaviour

    getType: ->
        "channel"

    requestAccept: ( signal, state ) ->
        availableRoutes = _.filter state.routes, (route) ->
            route.in and route.object is signal.source
        availableRoutes.length > 0 and state.capacity + 1 <= state.signals.length

    produce: ( state ) ->
        null

    accept: ( signal, state, callback ) ->
        callback signal
        _.delay state.signals.push, state.delay, signal
        @route state

    route: ( state ) ->
       _.each state.signals, (signal, index) ->
           availableRoutes = _.filter state.routing, (route, direction) ->
                route? and route.object isnt signal.source
           destination = availableRoutes[0]
           if destination.requestAccept signal
               destinatio.trigger 'accept', signal, (signal) ->
                   state.signals = _.without state.signals, signal

module.exports = exports = ChannelBehaviour
