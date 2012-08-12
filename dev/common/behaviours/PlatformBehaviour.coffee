S = {}
if require?
  _ = require 'underscore'
  S.Types = require '../config/Types'
  S.Logger = require '../util/Logger'
  S.Properties = require '../config/Properties'
else
  _ = window._
  S.Types = window.S.Types
  S.Logger = window.S.Logger
  S.Properties = window.S.Properties

class PlatformBehaviour

    constructor: ( @eventBus ) ->
        @log = S.Logger.createLogger name: 'PlatformBehaviour'

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

    accept: ( signal, state, callback ) ->
        callback signal
        if signal.owner?.id is state.owner.id or signal.owner.id is @eventBus.nonUserId state.owner
            state.signals.push { signal: signal, ready: Date.now()+state.delay }
            _.delay (-> state.field.platform.trigger 'route'), state.delay
        else
            state.life -= signal.strength
            @log.debug "signal dealt damage, life is:", state.life
            if state.life <= 0
                state.owner = signal.owner
                state.life = S.Properties.platform.life
                #@log.debug "[PlatformBehaviour]: source", signal.source
                @eventBus.trigger 'owner:platform', state.field.xy, signal.owner.id

    depleted: ( state ) ->


    route: ( state ) ->
        signalObj = state.signals.shift()
        if signalObj?
          if signalObj.ready >= Date.now()
            signal = signalObj.signal
            availableRoutes = []
            _.each state.routing, (route, direction) =>
                @log.debug "What happened to object in route", route.object, route
                if route.out and route.object.type?
                    availableRoutes.push [route, direction]
            if availableRoutes.length > 0
                destNum = state.routeCounter % availableRoutes.length
                state.routeCounter++
                destination = availableRoutes[destNum]

                @log.debug "availableRoutes", availableRoutes
                origOwner = signal.owner
                origSource = signal.source

                signal.source = state
                signal.owner = state.owner
                if destination[0].object.requestAccept signal
                  @eventBus.trigger 'move:signal', state.field.xy, destination[1]
                  @log.trace 'triggering accept on channel', Date.now()
                  destination[0].object.trigger 'accept', signal, (signal) =>
                    if state.signals.length > 0
                      state.field.platform.trigger 'route'
                else
                  signal.source = origSource
                  signal.owner = origOwner
                  state.signals.push signalObj

            else
              state.signals.push signalObj
          else
            state.signals.push signalObj
            _.delay (-> state.field.platform.trigger 'route'), 20

if module? and module.exports
  exports = module.exports = PlatformBehaviour
else
  window.S.PlatformBehaviour = PlatformBehaviour
