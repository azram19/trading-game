S = {}
if require?
  _ = require 'underscore'
else
  _ = window._

class PlatformBehaviour

    constructor: ( @eventBus ) ->

    actionMenu: ( state ) ->
        myName = S.Types.Entities.Names[state.type]
        menu = ['build:channel', 'routing', '/!platforminfo', "/:#{ myName }"]

    requestAccept: ( signal, state ) ->
        if signal.owner.id is state.owner.id
            availableRoutes = _.filter state.routing, (route) ->
                route.in or route.object is signal.source
            availableRoutes.length > 0 and state.capacity + 1 >= state.signals.length
        else
            true

    produce: ( state ) ->
        if state.field.resource.type?
          state.field.resource.trigger 'produce'

    accept: ( signal, state, callback ) ->
        callback signal
        if signal.owner.id is state.owner.id
            signal.source = state.field.platform
            signal.path.push state.field.platform
            addSignal = (signal) =>
                state.signals.push signal
                @route state
            _.delay addSignal, state.delay, signal
        else
            state.life -= signal.strength
            if state.life < 0
                state.owner = signal.owner
                #FIXME Reset life
                @eventBus.trigger 'owner:platform', state.field.xy, state

    depleted: ( state ) ->


    route: ( state ) ->
        console.log "signal is being routed"
        availableRoutes = []
        _.each state.routing, (route, direction) -> if route.out and route.object? 
            availableRoutes.push [route, direction]
        _.each state.signals, (signal) =>
            destNum = Math.ceil(Math.random()*100)%availableRoutes.length
            destination = availableRoutes[destNum]

            if destination[0].object.requestAccept signal
              @eventBus.trigger 'move:signal', state.field.xy, destination[1]

              destination[0].object.trigger 'accept', signal, (signal) ->
                state.signals = _.without state.signals, signal

if module? and module.exports
  exports = module.exports = PlatformBehaviour
else
  window.S.PlatformBehaviour = PlatformBehaviour
