Properties =
    platform:
        someField: "value"

    channel:
        someField: "value"

    HQ:
        someField: "value"

    signal:
        someField: "value"

    resource:
        someField: "value"

    resourceTypes:
        ["money", "bitches"]

    user:
        someField: "value"


if module? and module.exports
  exports = module.exports = Properties
else
  root['Properties'] = Properties
