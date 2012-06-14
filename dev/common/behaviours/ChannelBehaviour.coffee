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
      menu = ['routing']

    requestAccept: ( signal, state ) ->
        if signal.owner.id is state.owner.id
            availableRoutes = _.filter state.routing, (route) ->
                route.in or route.object.id is signal.source.id
            availableRoutes.length > 0 and state.capacity >= state.signals.length
        else
            true

    produce: ( state ) ->
        null

    accept: ( signal, state, callback ) ->
        callback signal
        if signal.owner.id is signal.owner.id
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

        console.log availableRoutes
        destination = availableRoutes[0]
        signal.source = state
        if destination[0].object.requestAccept signal
          console.log '[ChannelBehaviour] signal source is of type', signal.source.type
          if signal.source.type is S.Types.Entities.Channel
            @eventBus.trigger 'move:signal', state.field.xy, destination[1]

          destination[0].object.trigger 'accept', signal, (signal) ->
            state.signals = _.without state.signals, signal

if module? and module.exports
  exports = module.exports = ChannelBehaviour
else
  window.S.ChannelBehaviour = ChannelBehaviour
