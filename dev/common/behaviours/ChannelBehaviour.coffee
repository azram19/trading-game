if require?
  Types = require '../config/Types'
else
  Types = window.Types

class ChannelBehaviour

    constructor: ( @eventBus ) ->

    getType: ->
        Types.Entities.Channel

    actionMenu: ( state ) ->
      menu = []
      (
        if sth.object?
          menu.push 'routing:' + route
      ) for route, sth of state.routing

    requestAccept: ( signal, state ) ->
        if signal.owner.id is state.owner.id
            availableRoutes = _.filter state.routes, (route) ->
                route.in and route.object is signal.source
            availableRoutes.length > 0 and state.capacity + 1 <= state.signals.length
        else
            true

    produce: ( state ) ->
        null

    accept: ( signal, state, callback ) ->
        callback signal
        if signal.owner.id is signal.owner.id
            _.delay state.signals.push, state.delay, signal
            @route state
        else
            state.life -= signal.strength
            if state.life <= 0
                state.owner = signal.owner
                @eventBus.trigger 'owner:channel', state.field.xy, state.direction, state

    route: ( state ) ->
       _.each state.signals, (signal, index) ->
           availableRoutes = _.filter state.routing, (route, direction) ->
                route? and route.object.state.id isnt signal.source.state.id

           destination = availableRoutes[0].object

           if destination.requestAccept signal
              @eventBus.trigger 'move:signal', state.field.xy, destNum

              destination.trigger 'accept', signal, (signal) ->
                state.signals = _.without state.signals, signal

if module? and module.exports
  exports = module.exports = ChannelBehaviour
else
  window['ChannelBehaviour'] = ChannelBehaviour
