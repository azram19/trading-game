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
          possibleRoutes = []
          _.each state.routing, (route, direction) ->
            if not _.isEmpty(route.object)
              possibleRoutes.push (+direction)

          [x, y] = state.field.xy
          possibleChannels = @eventBus.getPossibleChannels x, y

          menu = [['build:channel', 'routing', '/:Platform', '/!platforminfo'], [possibleChannels, possibleRoutes]]

    requestAccept: ( signal, state ) ->
        if signal.owner.id is state.owner.id
          availableRoutes = _.filter state.routing, (route) ->
              route.in and route.object?.state?.id is signal.source.id
          availableRoutes.length > 0 and state.capacity >= state.signals.length
        else if signal.owner.id is @eventBus.nonUserId state.owner
          state.capacity > state.signals.length
        else
          true

    produce: ( state ) ->
        if state.field.resource.type?
          state.field.resource.trigger 'produce'

    accept: ( signal, state, callback, ownObject ) ->
        callback signal
        if signal.owner?.id is state.owner.id or S.Types.Resources.Gold <= signal.type <= S.Types.Resources.Resources
            addSignal = (signal) =>
                ownObject.state.signals.push signal
                ownObject.trigger 'route'
            _.delay addSignal, state.delay, signal
        else
            state.life -= signal.strength
            console.log "[PlatformBehaviour]: signal dealt damage, life is:", state.life
            if state.life <= 0
                state.owner = signal.owner       
                #FIXME Reset life
                #console.log "[PlatformBehaviour]: source", signal.source
                @eventBus.trigger 'owner:platform', state.field.xy, signal.owner.id

    depleted: ( state ) ->


    route: ( state, ownObject ) ->
        signal = ownObject.state.signals.shift()
        if signal?
          availableRoutes = []
          _.each state.routing, (route, direction) -> if route.out and route.object?.type?
              availableRoutes.push [route, direction]
          if availableRoutes.length > 0
              destNum = Math.ceil(Math.random()*100)%availableRoutes.length
              destination = availableRoutes[destNum]
              #console.log "[PlatformBehaviour]: availableRoutes", availableRoutes
              origOwner = signal.owner
              origSource = signal.source
 
              signal.source = state
              signal.owner = state.owner
              if destination[0].object.requestAccept signal
                @eventBus.trigger 'move:signal', state.field.xy, destination[1]
                # console.log '[PlatformBehaviour] triggering accept on channel', new Date()
                destination[0].object.trigger 'accept', signal, (signal) ->
                  if ownObject.state.signals.length > 0
                    ownObject.trigger 'route'
              else
                signal.source = origSource
                signal.owner = origOwner
                ownObject.state.signals.push signal

          else
            ownObject.state.signals.push signal

if module? and module.exports
  exports = module.exports = PlatformBehaviour
else
  window.S.PlatformBehaviour = PlatformBehaviour
