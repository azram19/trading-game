#node.js requirements
if require?
  _ = require 'underscore'
  Signal = require '../objects/signal'

class ResourceBehaviour

    constructor: ( @resourceType ) ->

    getType: ->
        @resourceType

    requestAccept: ( signal, state ) ->

    accept: ( signal, callback ) ->

    route: ( state ) ->

    produce: ( state ) ->
        production = =>
            #check if we have engough resources to extract
            if state.life < state.extraction
                #resource depleted
                newSignal = new Signal 0, @resourceType, state.field.resource
                state.field.platform.trigger "depleted", newSignal
            else
                #we have enough rousrces, mining...
                newSignal = new Signal state.extraction, @resourceType, state.field.resource

                #can the platform accept the signal
                acceptable = state.field.platform.requestAccept newSignal

                if acceptable
                    #send the signal
                    state.life -= state.extraction
                    signals.push newSignal

                    state.field.platform.trigger "accept", newSignal, (signal) ->
                        state.signals = _.without state.signals, signal

        setInterval production, state.delay

if exports?
  if module? and module.exports
    exports = module.exports = ResourceBehaviour
else
  root['ResourceBehaviour'] = ResourceBehaviour
