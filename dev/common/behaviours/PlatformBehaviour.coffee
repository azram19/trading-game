S = {}
if require?
  _ = require 'underscore'
  S.Types = require '../config/Types'
else
  _ = window._
  S.Types = window.S.Types

class PlatformBehaviour

    constructor: ( @eventBus ) ->

    actionMenu: ( state ) ->
        myName = S.Types.Entities.Names[state.type]
        menu = ['build:channel', 'routing']#, '/!platforminfo', "/:#{ myName }"]

    requestAccept: ( signal, state ) ->
        if signal.owner.id is state.owner.id
            availableRoutes = _.filter state.routing, (route) ->
                route.in and route.object?.state?.id is signal.source.id
            availableRoutes.length > 0 and state.capacity >= state.signals
        else
            true

    produce: ( state ) ->
        if state.field.resource.type?
          state.field.resource.trigger 'produce'

    accept: ( signal, state, callback ) ->
        callback signal
        if signal.owner?.id is state.owner.id or S.Types.Resources.Gold <= signal.type <= S.Types.Resources.Resources
            addSignal = (signal) =>
                state.signals++
                console.log "[PlatformBehaviour]: new signal.source", signal.source
                signal.source = state
                signal.owner = state.owner
                @route state, signal
            _.delay addSignal, state.delay, signal
        else
            state.life -= signal.strength
            if state.life < 0
                state.owner = signal.owner
                #FIXME Reset life
                @eventBus.trigger 'owner:platform', state.field.xy, state

    depleted: ( state ) ->


    route: ( state, signal ) ->
        availableRoutes = []
        _.each state.routing, (route, direction) -> if route.out and route.object.type? 
            availableRoutes.push [route, direction]   

        destNum = Math.ceil(Math.random()*100)%availableRoutes.length
        destination = availableRoutes[destNum]

        if destination[0].object.requestAccept signal
          @eventBus.trigger 'move:signal', state.field.xy, destination[1]

          destination[0].object.trigger 'accept', signal, (signal) ->
            state.signals--

if module? and module.exports
  exports = module.exports = PlatformBehaviour
else
  window.S.PlatformBehaviour = PlatformBehaviour
