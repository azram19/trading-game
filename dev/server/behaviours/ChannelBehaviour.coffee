class ChannelBehaviour

    getType: ->
        "channel"

    requestAccept: ( signal, state ) ->
        if signal.owner is state.owner
            availableRoutes = _.filter state.routes, (route) ->
                route.in and route.object is signal.source
            availableRoutes.length > 0 and state.capacity + 1 <= state.signals.length
        else
            true

    produce: ( state ) ->
        null

    accept: ( signal, state, callback ) ->
        callback signal
        if signal.owner is signal.owner
            _.delay state.signals.push, state.delay, signal
            @route state
        else
            state.life -= signal.strength
            if state.life <= 0
                state.owner = signal.owner
                # Trigger UI event

    route: ( state ) ->
       _.each state.signals, (signal, index) ->
           availableRoutes = _.filter state.routing, (route, direction) ->
                route? and route.object isnt signal.source
           destination = availableRoutes[0]
           if destination.requestAccept signal
               destinatio.trigger 'accept', signal, (signal) ->
                   state.signals = _.without state.signals, signal

if module? and module.exports
  exports = module.exports = ChannelBehaviour
else
  root['ChannelBehaviour'] = ChannelBehaviour
