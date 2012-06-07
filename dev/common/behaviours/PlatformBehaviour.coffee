class PlatformBehaviour

    constructor: ( @platformType, @eventBus ) ->

    getType: ->
        @platformType

    actionMenu: ( state ) ->
      menu = ['build:channel', 'routing']

    requestAccept: ( signal, state ) ->
        if signal.owner.id is state.owner.id
            availableRoutes = _.filter state.routing, (route, direction) ->
                route.in && route.object is signal.source
            availableRoutes.length > 0 and state.capacity + 1 <= state.signals.length

    produce: ( state ) ->
        if state.field.resource.type?
          state.field.resource.trigger 'produce'

    accept: ( signal, state, callback ) ->
        callback signal
        if signal.owner.id is state.owner.id
            signal.source = state.field.platform
            signal.path.push state.field.platform
            _.delay state.signals.push, state.delay, signal
            @route state
        else
            state.life -= signal.strength
            if state.life < 0
                state.owner = signal.owner
                @eventBus.trigger 'owner:platform', state.field.xy, state

    depleted: ( state ) ->


    route: ( state ) ->
        availableRoutes = _.filter state.routing, (route, direction) ->
            route.out

        _.each state.signals, (signal) ->
            destNum = Math.ceil(Math.random()*100)%availableRoutes.length
            availableRoutes[destNum].object.trigger 'accept', signal, (signal) ->
                state.signals = _.without state.signals, signal

if module? and module.exports
  exports = module.exports = PlatformBehaviour
else
  window['PlatformBehaviour'] = PlatformBehaviour
