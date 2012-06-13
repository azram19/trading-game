#node.js requirements
S = {}
if require?
  _ = require 'underscore'
  S.SignalFactory = require '../config/SignalFactory'
  S.Types = require '../config/Types'
else
  _ = window._
  S.SignalFactory = window.S.SignalFactory
  S.Types = window.S.Types

class ResourceBehaviour

    constructor: ( @resourceType, @eventBus ) ->

    actionMenu: ( state ) ->
      []

    requestAccept: ( signal, state ) ->

    accept: ( signal, callback ) ->

    route: ( state ) ->

    produce: ( state ) ->
        production = =>
            #check if we have engough resources to extract
            if state.life < state.extraction
                #resource depleted
                if @PID?
                    clearInterval @PID
            else
                #we have enough resources, mining...
                newSignal = S.SignalFactory.build S.Types.Entities.Signal, @eventBus, state.extraction, @resourceType, state.field.platform
                newSignal.path.push state.field.xy
                @eventBus.trigger 'resource:produce', state.field.xy, state.extraction, @resourceType
                console.log newSignal, "signal"
                #can the platform accept the signal
                acceptable = state.field.platform.requestAccept newSignal

                if acceptable
                    #send the signal
                    state.life -= state.extraction
                    state.signals.push newSignal
                    console.log "acceptable"
                    state.field.platform.trigger "accept", newSignal, (signal) ->
                        state.signals = _.without state.signals, signal

        @PID = setInterval production, state.delay

if module? and module.exports
  exports = module.exports = ResourceBehaviour
else
  window.S.ResourceBehaviour = ResourceBehaviour
