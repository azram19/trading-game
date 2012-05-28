class ObjectFactory

    kindClassMap:
        channel: "ChannelBehaviour"
        hq: "HQBehaviour"
        platform: "PlatformBehaviour"

    create: ( kind, state ) ->
        new GameObject (new @kindClassMap.kind), state
