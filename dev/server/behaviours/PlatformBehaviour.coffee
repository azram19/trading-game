class PlatformBehaviour

    constructor: ( @platformType ) ->

    getType: ->
        @platformType

    requestAccept: ( signal, state ) ->
        availableRoutes = _.filter state.routing, (route, direction) ->
            route.in && route.object is signal.source
        availableRoutes.length > 0 and state.capacity + 1 <= state.signals.length

    produce: ( state ) ->
        state.field.resource.trigger 'produce'

    accept: ( signal, state, callback ) ->
        callback signal
        signal.source = state.field.platform
        _.delay state.signals.push, state.delay, signal
        @route state

    route: ( state ) ->
        availableRoutes = _.filter state.routing, (route, direction) ->
            route.out

        _.each state.signals, (signal) ->
            availableRoutes[0].object.trigger 'accept', signal, (signal) ->
                state.signals = _.without state.signals, signal

module.exports = exports = PlatformBehaviour
