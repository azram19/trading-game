# Class representing in game signal
class Signal

    ###
    # Strength of the signal
    # Has different meanings when reaching different fields
    # When signal reaches storage or HQ strength translates into amount of
    # resouces player receives of given type
    # If the signal reaches enemy structure strength is the parameter which
    # determines the amount of damage dealt to the structure
    ###
    strength: 0
    # Most recent source of the signal
    source: {}
    # Type of signal in case we\'re carrying resources
    type: 0
    # Player who generated the channel
    owner: {}

    constructor: ( @events, @strength, @type, @source ) ->
        @owner = @source.owner

if module? and module.exports
  exports = module.exports = Signal
else
  window.S.Signal = Signal
