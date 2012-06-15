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

    accept: ( signal, state, callback, ownObject ) ->

    route: ( state, ownObject ) ->

    produce: ( state ) ->
        production = =>
            #console.log "[Resource:produce]"
            #console.log state.life
            #check if we have engough resources to extract
            if state.life <= 0
                #resource depleted
                if @PID?
                    clearInterval @PID
            else
                #we have enough resources, mining...
                if not state.field.platform.state.owner
                  console.log ["Missing owner - Res"], state.field
                extractAmount = if state.life >= state.extraction then state.extraction else state.life
                newSignal = S.SignalFactory.build S.Types.Entities.Signal, @eventBus, extractAmount, @resourceType, state
                @eventBus.trigger 'resource:produce', state.field.xy, state.extraction, @resourceType
                #can the platform accept the signal
                acceptable = state.field.platform.requestAccept newSignal
                #console.log '[ResourceBehaviour] the resource is acceptable', acceptable
                if acceptable
                    #send the signal
                    state.life -= extractAmount
                    #console.log '[ResourceBehaviour] triggering accept on platform', new Date()
                    state.field.platform.trigger "accept", newSignal, (signal) ->
        #production()
        @PID = setInterval ( ->
          console.log '[ResourceBehaviour] Trigger resource production', new Date()
          production()
        ), state.delay

if module? and module.exports
  exports = module.exports = ResourceBehaviour
else
  window.S.ResourceBehaviour = ResourceBehaviour
