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
        if state.capacity <= state.signals.length
          @eventBus.trigger 'full:channel', state.fields

        if signal.owner.id is state.owner.id
            availableRoutes = _.filter state.routing, (route) ->
                #console.log "[ChannelBehaviour] availableRoutes", route.object.state, signal.source
                route.in and route.object?.state?.id is signal.source.id
            availableRoutes.length > 0 and state.capacity > state.signals.length
        else
            true

    produce: ( state ) ->
        null

    accept: ( signal, state, callback, ownObject ) ->
        callback signal
        if state.owner.id is signal.owner.id
            addSignal = (signal) =>
                ownObject.state.signals.push signal
                #console.log "[ChannelBehaviour]: now i will call @route", new Date()
                ownObject.trigger 'route'
            _.delay addSignal, state.delay, signal
        else
            state.life -= signal.strength
            console.log "[ChannelBehaviour]: signal dealt damage, life is:", state.life
            if state.life <= 0
                state.owner = signal.owner
                #console.log "[ChannelBehaviour]: source", signal.source
                @eventBus.trigger 'owner:channel', state.fields, signal.source.fields, signal.owner.id

    route: ( state, ownObject ) ->
      signal = ownObject.state.signals.shift()
      if signal?
        availableRoutes = []
        #console.log "[ChannelBehaviour]: state.routing", state.routing
        _.each state.routing, (route, direction) ->
          #console.log "[ChannelBehaviour]: channel", route.object?.state?.id, signal.source.id, direction
          if route.object.type? and route.object?.state?.name isnt signal.source.name
            availableRoutes.push [route, direction]
            #console.log "[ChannelBehaviour]: availableRoutes", availableRoutes
        if availableRoutes.length > 0
          destination = availableRoutes[0]
          origSource = signal.source
          origOwner = signal.owner
 
          signal.source = state
          signal.owner = state.owner
          if destination[0].object.requestAccept signal
            #console.log "[ChannelBehaviour]: object.type", destination[0].object.type()
            if destination[0].object.type() is S.Types.Entities.Channel
              #console.log '[ChannelBehaviour] fields references', state.fields, destination[0].object.state.fields
              field = _.intersection state.fields, destination[0].object.state.fields
              field2 = _.difference destination[0].object.state.fields, state.fields
              #console.log "[ChannelBehaviour]: eventBus", @eventBus
              dest = @eventBus.directionGet state.owner, field[0].xy[0], field[0].xy[1], field2[0].xy[0], field2[0].xy[1]
              #console.log "[ChannelBehaviour]: moving", field[0].xy, dest
              @eventBus.trigger 'move:signal', field[0].xy, dest
 
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
  exports = module.exports = ChannelBehaviour
else
  window.S.ChannelBehaviour = ChannelBehaviour
