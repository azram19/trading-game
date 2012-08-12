#node.js requires
S = {}
if require?
  _ = require 'underscore'
  S.SignalFactory = require '../config/SignalFactory'
  S.Logger = require '../util/Logger'
  S.Types = require '../config/Types'
else
  _ = window._
  S.SignalFactory = window.S.SignalFactory
  S.Types = window.S.Types
  S.Logger = window.S.Logger

class ResourceBehaviour

    constructor: ( @resourceType, @eventBus ) ->
      @log = S.Logger.createLogger name: 'ResourceBehaviour'

    actionMenu: ( state ) ->
      []

    requestAccept: ( signal, state ) ->

    accept: ( signal, state, callback ) ->

    route: ( state ) ->

    produce: ( state ) ->
        production = =>
            #@log.debug "[Resource:produce]"
            #@log.trace state.life
            #check if we have engough resources to extract
            if state.life <= 0
                @log.debug "Resource", @resourceType, "depleted at", state.field.xy
                if @PID?
                    clearInterval @PID
            else
                #we have enough resources, mining...
                if not state.field.platform.state.owner
                  @log.error "Missing owner", state.field

                extractAmount = if state.life >= state.extraction then state.extraction else state.life
                newSignal = S.SignalFactory.build S.Types.Entities.Signal, @eventBus, extractAmount, @resourceType, state
                @eventBus.trigger 'resource:produce', state.field.xy, state.extraction, @resourceType
                #can the platform accept the signal
                acceptable = state.field.platform.requestAccept newSignal
                #@log.debug 'the resource is acceptable', acceptable
                if acceptable
                    #send the signal
                    state.life -= extractAmount
                    #@log.debug 'triggering accept on platform', new Date()
                    state.field.platform.trigger "accept", newSignal, (signal) ->
        @PID = setInterval ( =>
            @log.trace 'Trigger resource production', Date.now()
            production()
        ), state.delay

if module? and module.exports
  exports = module.exports = ResourceBehaviour
else
  window.S.ResourceBehaviour = ResourceBehaviour
