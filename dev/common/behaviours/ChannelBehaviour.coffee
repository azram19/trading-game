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
        if state.capacity < state.signals
          @eventBus.trigger 'full:channel', state.field.xy

        if signal.owner.id is state.owner.id
            availableRoutes = _.filter state.routing, (route) ->
                console.log "[ChannelBehaviour] availableRoutes", route.object.state, signal.source
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
                console.log "[ChannelBehaviour]: now i will call @route", new Date()
                @route state, signal
            _.delay addSignal, state.delay, signal
        else
            state.life -= signal.strength
            if state.life <= 0
                state.owner = signal.owner
                @eventBus.trigger 'owner:channel', state.field.xy, state.direction, state

    route: ( state, signal ) ->
      availableRoutes = []
      console.log "[ChannelBehaviour]: state.routing", state.routing
      _.each state.routing, (route, direction) ->
        console.log "[ChannelBehaviour]: channel", route.object?.state?.id, signal.source.id, direction
        if route.object.type? and route.object?.state?.name isnt signal.source.name
          availableRoutes.push [route, direction]
      console.log "[ChannelBehaviour]: availableRoutes", availableRoutes
      if availableRoutes.length > 0
        destination = availableRoutes[0]

        signal.source = state
        signal.owner = state.owner
        if destination[0].object.requestAccept signal
          console.log "[ChannelBehaviour]: object.type", destination[0].object.type()
          if destination[0].object.type() is S.Types.Entities.Channel
            console.log '[ChannelBehaviour] fields references', state.fields, destination[0].object.state.fields
            field = _.intersection state.fields, destination[0].object.state.fields
            field2 = _.difference destination[0].object.state.fields, state.fields
            console.log "[ChannelBehaviour]: eventBus", @eventBus
            dest = @eventBus.directionGet state.owner, field[0].xy[0], field[0].xy[1], field2[0].xy[0], field2[0].xy[1]
            console.log "[ChannelBehaviour]: moving", field[0].xy, dest
            @eventBus.trigger 'move:signal', field[0].xy, dest

          destination[0].object.trigger 'accept', signal, (signal) ->
            state.signals--

if module? and module.exports
  exports = module.exports = ChannelBehaviour
else
  window.S.ChannelBehaviour = ChannelBehaviour
