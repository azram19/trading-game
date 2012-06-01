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
        state.field.resource.trigger 'produce'
        production = =>
                state.owner.addResources new Type1Resource(), state.extraction
                state.owner.addResources new Type2Resource(), state.extraction
        setInterval production, state.delay

    accept: ( signal, state, callback ) ->
        callback signal
        if signal.owner is state.owner
            state.owner.addResources signal
        else
            state.life -= signal.strength
            if state.life <= 0
                null
                #Trigger UI event
                #GameEngine.trigger 'player:dead', state.owner

    route: ( state ) ->

if exports?
  if module? and module.exports
    exports = module.exports = HQBehaviour
else
  root['HQBehaviour'] = HQBehaviour
