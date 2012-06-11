S = {}
if require?
    S.Types = require './Types'
    _ = require('underscore')._
else
    S.Types = window.S.Types
    _ = window._

Properties =
    platform:
        type: S.Types.Entities.Platforms.Normal
        id: 0
        fov: 1
        name: 'Object'
        field: {}
        signals: []
        routing: {}
        delay: 1000
        extraction: 20
        capacity: 10
        life: 100

    channel:
        type: S.Types.Entities.Channel
        id: 0
        fov: 1
        name: 'Channel'
        field: {}
        signals: []
        routing: {}
        delay: 1000
        extraction: 20
        capacity: 10
        life: 100
        someField: "value"

    HQ:
        type: S.Types.Entities.Platforms.HQ
        id: 0
        fov: 1
        name: 'HQ'
        field: {}
        signals: []
        routing: {}
        delay: 1000
        extraction: 20
        capacity: 10
        life: 100

    signal:
        type: S.Types.Entities.Signal
        id: 0
        name: 'Signal'
        strength: 0
        source: {}
        resource: ""
        path: []

    resource:
        type: S.Types.Resources.Food
        id: 0
        fov: 0
        name: 'Resource'
        field: {}
        signals: []
        routing: {}
        delay: 1000
        extraction: 20
        capacity: 10
        life: 100

    player:
        resources: {}

(
    Properties.player.resources[S.Types.Resources.Names[i]] = S.Types.Resources.Amounts[i]
) for i in [0...S.Types.Resources.Names.length]

defaultRoute =
    object: null
    in: true
    out: true

( (
    Properties[field].routing[i] = _.clone defaultRoute
) for i in [0..5] ) for field in ['channel', 'HQ', 'platform']

if module? and module.exports
  exports = module.exports = Properties
else
  window.S.Properties = Properties
