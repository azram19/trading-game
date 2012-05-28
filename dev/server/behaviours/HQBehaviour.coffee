class HQBehaviour
    produce: ( state ) ->


    accept: ( signal, state, callback ) ->
            if signal.owner is state.owner
            state.owner.addResources signal.type, signal.content
        else
            state.life -= signal.content

        if state.life <= 0
            GameEngine.trigger 'player:dead', state.owner

    route: ( state ) ->

