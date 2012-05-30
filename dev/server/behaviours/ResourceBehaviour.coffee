class ResourceBehaviour

    constructor: ( @resourceType ) ->

    getType: ->
        @resourceType

    requestAccept: ( signal, state ) ->

    accept: ( signal, callback ) ->

    route: ( state ) ->

    produce: ( state ) ->
        production = =>
            state.life -= state.extraction
            newSignal = new Signal state.extraction, @resourceType, state.field.resource
            signals.push newSignal
            state.field.platform.trigger "accept", newSignal, (signal) ->
                state.signals = _.without state.signals, signal

        setInterval produciton, state.delay

module.exports = exports = ResourceBehaviour
