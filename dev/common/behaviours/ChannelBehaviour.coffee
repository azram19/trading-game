S = {}
if require?
  S.Types = require '../config/Types'
  _ = require 'underscore'
else
  S.Types = window.S.Types
  _ = window._

class ChannelBehaviour

    constructor: ( @eventBus ) ->

    actionMenu: ( state ) ->
      possibleRoutes = []
      _.each state.routing, (route, direction) ->
        if not _.isEmpty(route.object)
          possibleRoutes.push (+direction)
      menu = [['routing'], [possibleRoutes]]

    requestAccept: ( signal, state ) ->
        if signal.owner.id is state.owner.id
            availableRoutes = _.filter state.routing, (route) ->
                route.in and route.object?.state?.id is signal.source.id
            availableRoutes.length > 0 and state.capacity >= state.signals
        else
            true

    produce: ( state ) ->
        null

    accept: ( signal, state, callback ) ->
        callback signal
        if signal.owner.id is signal.owner.id
            addSignal = (signal) =>
                state.signals++
                console.log "[ChannelBehaviour]: old signal.source", signal.source
                signal.source = state
                console.log "[ChannelBehaviour]: new signal.source", signal.source
                signal.owner = state.owner
                @route state, signal
            _.delay addSignal, state.delay, signal
        else
            state.life -= signal.strength
            if state.life <= 0
                state.owner = signal.owner
                @eventBus.trigger 'owner:channel', state.field.xy, state.direction, state

    route: ( state, signal ) ->
      availableRoutes = []
      _.each state.routing, (route, direction) -> 
       #console.log "[ChannelBehaviour]: channel", route.object?.state?.id, signal.source.id, direction
        if route.object.type? and route.object?.state?.id isnt signal.source.id
          availableRoutes.push [route, direction]
      
      destination = availableRoutes[0]
      if destination[0].object.requestAccept signal
        if destination[0].object.type is S.Types.Entities.Channel
          @eventBus.trigger 'move:signal', state.field.xy, destination[1]

        destination[0].object.trigger 'accept', signal, (signal) ->
          state.signals--

if module? and module.exports
  exports = module.exports = ChannelBehaviour
else
  window.S.ChannelBehaviour = ChannelBehaviour
