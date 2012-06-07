if require?
    SignalFactory = require '../config/SignalFactory'
    Types = require '../config/Types'
else
    Types = window.Types
    SignalFactory = window.SignalFactory

class HQBehaviour

    constructor: ( @eventBus ) ->

    getType: ->
        Types.Platforms.HQ

    actionMenu: ( state ) ->
      menu = []
      (
        if sth.object?
          menu.push 'routing:' + route
        else
          menu.push 'build:channel:' + route
      ) for route, sth of state.routing

    requestAccept: ( signal, state ) ->
        if signal.owner is state.owner
            availableRoutes = _.filter state.routing, (route, direction) ->
                route.in && route.object is signal.source
            availableRoutes.length > 0 and state.capacity + 1 <= state.signals.length
        else
            true

    produce: ( state ) ->
        if state.field.resource.type?
            state.field.resource.trigger 'produce'
        production = =>
                (
                    state.owner.addResource(SignalFactory.build Types.Entities.Signal, @eventBus, state.extraction, Types.Resources[res], state.field.platform)
                    @eventBus.trigger 'resource:produce', state.field.xy, state.extraction, Types.Resources[res]
                ) for res in Types.Resources.Names
        setInterval production, state.delay

    accept: ( signal, state, callback ) ->
        callback signal
        console.log signal
        if signal.owner.id is state.owner.id
            state.owner.addResource signal
            @eventBus.trigger 'resource:receive', state.field.xy, signal.strength, signal.type
        else
            state.life -= signal.strength
            if state.life <= 0
                @eventBus.trigger 'player:lost', state.owner

    route: ( state ) ->

if module? and module.exports
  exports = module.exports = HQBehaviour
else
  window['HQBehaviour'] = HQBehaviour
