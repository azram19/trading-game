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
                route.in or route.object is signal.source
            availableRoutes.length > 0 and state.capacity >= state.signals.length
        else
            true

    produce: ( state ) ->
        null

    accept: ( signal, state, callback ) ->
        callback signal
        if signal.owner.id is signal.owner.id
            signal.source = state
            signal.path.push state
            addSignal = (signal) =>
                state.signals.push signal
                @route state
            _.delay addSignal, state.delay, signal
        else
            state.life -= signal.strength
            if state.life <= 0
                state.owner = signal.owner
                @eventBus.trigger 'owner:channel', state.field.xy, state.direction, state

    route: ( state ) ->
      availableRoutes = []
      _.each state.signals, (signal, index) =>
        _.each state.routing, (route, direction) -> if route.object.type? and route.object.id isnt signal.source.id 
          availableRoutes.push [route, direction]

        destination = availableRoutes[0]
        console.log '[ChannelBehaviour] type of signal destination', signal.type
        if destination[0].object.requestAccept signal
          if signal.type is S.Types.Entities.Channel
            @eventBus.trigger 'move:signal', state.field.xy, destination[1]

          destination[0].object.trigger 'accept', signal, (signal) ->
            state.signals = _.without state.signals, signal
            console.log "[CHANNEL Behav]: state.signals", state.signals

if module? and module.exports
  exports = module.exports = ChannelBehaviour
else
  window.S.ChannelBehaviour = ChannelBehaviour
