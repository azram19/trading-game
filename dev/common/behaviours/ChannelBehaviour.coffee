S = {}
if require?
  S.Types = require '../config/Types'
  S.Properties = require '../config/Properties'
  S.Logger = require '../util/Logger'
  _ = require 'underscore'
else
  S.Properties = window.S.Properties
  S.Types = window.S.Types
  S.Logger = window.S.Logger
  _ = window._

class ChannelBehaviour

    constructor: ( @eventBus ) ->
        @log = S.Logger.createLogger name: 'ChannelBehaviour'

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
            availableRoutes = _.filter state.routing, (route) =>
                @log.debug "availableRoutes", route.object.state, signal.source
                route.in and route.object?.state?.id is signal.source.id
            availableRoutes.length > 0 and state.capacity > state.signals.length
        else
            true

    produce: ( state ) ->
        null

    accept: ( signal, state, callback ) ->
        callback signal
        if state.owner.id is signal.owner.id
            state.signals.push { signal: signal, ready: Date.now()+state.delay }
            @log.debug 'field channels', state.fields[0].channels
            channelObj = _.filter state.fields[0].channels, (channel) ->
                channel.type? and channel.state.id is state.id
            @log.debug "ourselves", channelObj
            _.delay (-> channelObj[0].trigger 'route'), state.delay
        else
            state.life -= signal.strength
            @log.debug "signal dealt damage, life is:", state.life
            if state.life <= 0
                state.owner = signal.owner
                state.life  = S.Properties.channel.life
                @log.trace "source", signal.source
                if signal.source.type is S.Types.Entities.Channel
                  @log.debug "owning channel"
                  @eventBus.trigger 'owner:channel', state.fields, signal.source.fields, signal.owner.id
                else
                  @eventBus.trigger 'owner:channel', state.fields, [signal.source.field], signal.owner.id

    route: ( state ) ->
      signalObj = state.signals.shift()
      if signalObj?
        channelObj = _.filter state.fields[0].channels, (channel) ->
            channel.type? and channel.state.id is state.id

        if signalObj.ready >= Date.now()
          signal = signalObj.signal
          availableRoutes = []
          @log.debug "state.routing", state.routing
          _.each state.routing, (route, direction) =>
            @log.debug "channel", route.object?.state?.id, signal.source.id, direction
            if route.object.type? and route.object?.state?.name isnt signal.source.name
              availableRoutes.push [route, direction]
              @log.debug "availableRoutes", availableRoutes
          if availableRoutes.length > 0
            destination = availableRoutes[0]
            origSource = signal.source
            origOwner = signal.owner

            signal.source = state
            signal.owner = state.owner
            if destination[0].object.requestAccept signal
              @log.debug "object.type", destination[0].object.type()
              if destination[0].object.type() is S.Types.Entities.Channel
                @log.trace 'fields references', state.fields, destination[0].object.state.fields
                field = _.intersection state.fields, destination[0].object.state.fields
                field2 = _.difference destination[0].object.state.fields, state.fields
                @log.trace "eventBus", @eventBus
                dest = @eventBus.directionGet state.owner, field[0].xy[0], field[0].xy[1], field2[0].xy[0], field2[0].xy[1]
                @log.trace "moving", field[0].xy, dest
                @eventBus.trigger 'move:signal', field[0].xy, dest

              destination[0].object.trigger 'accept', signal, (signal) ->
                if state.signals.length > 0
                  channelObj[0].trigger 'route'
            else
              signal.source = origSource
              signal.owner = origOwner
              state.signals.push signalObj
          else
            state.signals.push signalObj
        else
          state.signals.push signalObj
          _.delay (-> channelObj[0].trigger 'route'), 20

if module? and module.exports
  exports = module.exports = ChannelBehaviour
else
  window.S.ChannelBehaviour = ChannelBehaviour
