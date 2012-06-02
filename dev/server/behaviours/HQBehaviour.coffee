class HQBehaviour

    getType: ->
        "hq"

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
                state.owner.addResource 'money', state.extraction
                state.owner.addResource 'bitches', state.extraction
        setInterval production, state.delay

    accept: ( signal, state, callback ) ->
        callback signal
        if signal.owner is state.owner
            state.owner.addResource signal
        else
            state.life -= signal.strength
            if state.life <= 0
                null
                #Trigger UI event
                #GameEngine.trigger 'player:dead', state.owner

    route: ( state ) ->

if module? and module.exports
  exports = module.exports = HQBehaviour
else
  root['HQBehaviour'] = HQBehaviour
