# Abstraction of object state of any channel or platform
class ObjectState

    # Field the game object belongs to
    field: {}
    # Player object 
    owner: {}
    # Routing table for given object
    routing: {}
    # Signals currently at this object
    signals: []
    # Either life of the object or amount of resources held
    life: 0
    # Amount of signals that this game object can hold at any given time
    capacity: 10
    # Amount of time each signal must wait at the platform before being routed
    delay: 1000

module.exports = exports = ObjectState