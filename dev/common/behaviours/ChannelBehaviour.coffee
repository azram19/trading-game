if require?
  Types = require '../config/Types'
else
  Types = window.Types

class ChannelBehaviour

    constructor: ( @eventBus ) ->

    getType: ->
        Types.Entities.Channel

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
                @eventBus.trigger 'owner:channel', state.field.xy, state.direction, state.owner

    route: ( state ) ->
       _.each state.signals, (signal, index) ->
           availableRoutes = _.filter state.routing, (route, direction) ->
                route? and route.object isnt signal.source
           destNum = Math.ceil(Math.random()*100)%availableRoutes.length
           destination = availableRoutes[destNum]
           if destination.requestAccept signal
              @eventBus.trigger 'move:signal', state.field.xy, destNum
              destination.trigger 'accept', signal, (signal) ->
                state.signals = _.without state.signals, signal

if module? and module.exports
  exports = module.exports = ChannelBehaviour
else
  window['ChannelBehaviour'] = ChannelBehaviour
