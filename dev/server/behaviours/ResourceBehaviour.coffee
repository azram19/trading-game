class ResourceBehaviour

    getType: ->
        "resource"

    requestAccept: ( signal, state ) ->

    accept: ( signal, callback ) ->

    route: ( state ) ->

    produce: ( state ) ->
        production = =>
            newSignal = new Signal(100, state.type)
            signals.push newSignal
            state.field.platform.trigger "accept", newSignal, (signal) ->
                state.signals = _.without state.signals, signal

        setInterval produciton, state.delay
