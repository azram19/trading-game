# Abstraction of object state of any channel or platform
class ObjectState

    constructor: ->
        # Type of the object
        @type = 0
        # FOV - distance in which fields are visible from this one
        @fov = 1
        # Object owner
        @owner = {}
        # Unique object id
        @id = 0
        # Object name
        @name = 'Object'
        # Field the game object belongs to
        @field = {}
        # Signals currently at this object
        @signals = []
        # Routing table for given object
        @routing = {}
        (@routing[i] =
            in: false
            out: false
            object: null) for i in [0..5]
        # Amount of time each signal must wait at the platform before being routed
        @delay = 1000
        # Amount of resources that are produced each time
        @extraction = 20
        # Amount of signals that this game object can hold at any given time
        @capacity = 10
        # Either life of the object or amount of resources held
        @life = 100
        @routeCounter = 0

if module? and module.exports
  exports = module.exports = ObjectState
else
  window.S.ObjectState = ObjectState
