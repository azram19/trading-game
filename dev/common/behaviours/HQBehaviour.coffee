S = {}
if require?
    S.SignalFactory = require '../config/SignalFactory'
    S.Types = require '../config/Types'
else
    S.Types = window.S.Types
    S.SignalFactory = window.S.SignalFactory

class HQBehaviour

    constructor: ( @eventBus ) ->

    actionMenu: ( state ) ->
      possibleRoutes = []
      _.each state.routing, (route, direction) ->
        if not _.isEmpty(route.object)
          possibleRoutes.push (+direction)

      [x, y] = state.field.xy
      possibleChannels = @eventBus.getPossibleChannels x, y

      menu = [['build:channel', 'routing', '/:HQ', '/!platforminfo'], [possibleChannels, possibleRoutes]]

    requestAccept: ( signal, state ) ->
        true

    produce: ( state ) ->
        if state.field.resource.type?
            state.field.resource.trigger 'produce'
        production = =>
                (
                    if not state.field.platform.state.owner
                        console.log ["Missing owner - HQ"], state.field
                    state.owner.addResource(S.SignalFactory.build S.Types.Entities.Signal, @eventBus, state.extraction, S.Types.Resources[res], state.field.platform)
                    #@eventBus.trigger 'resource:produce', state.field.xy, state.extraction, S.Types.Resources[res]
                ) for res in S.Types.Resources.Names
        setInterval production, state.delay

    accept: ( signal, state, callback, ownObject ) ->
        callback signal
        if signal.owner.id is state.owner.id
            console.log "[HQBehaviour]: I accept a signal"
            state.owner.addResource signal
            @eventBus.trigger 'resource:receive', state.field.xy, signal.strength, signal.type
        else
            state.life -= signal.strength
            if state.life <= 0
                @eventBus.trigger 'player:lost', state.owner

    route: ( state, ownObject ) ->

if module? and module.exports
  exports = module.exports = HQBehaviour
else
  window.S.HQBehaviour = HQBehaviour
