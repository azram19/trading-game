class ChannelBehaviour
    produce: ( state ) ->

    accept: ( signal, state, callback ) ->
        if state.signals.length is state.capacity
            callback signal
        else
            _.delay state.signals.push, state.delay, signal
            @route state

    route: ( state ) ->
        self = @
       _.each state.signals, (signal, index) ->
           destination = {}
           if signal.source is state.neighbours[0]
               destination = state.neighbours[1]
           else
                destination = state.neighbours[0]
            
            remove = true
            destination.trigger 'accept', signal, (signal) ->
                remove = false

            

