if require?
    Types = require './Types'
    _ = require('underscore')._
else
    Types = window.Types
    _ = window._

Properties =
    platform:
        id: 0
        name: 'Object'
        field: {}
        signals: []
        routing: {}
        delay: 1000
        extraction: 20
        capacity: 10
        life: 100

    channel:
        id: 0
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
        id: 0
        name: 'HQ'
        field: {}
        signals: []
        routing: {}
        delay: 1000
        extraction: 20
        capacity: 10
        life: 100

    signal:
        id: 0
        name: 'Signal'
        strength: 0
        source: {}
        resource: ""
        path: []

    resource:
        id: 0
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
    Properties.player.resources[Types.Resources.Names[i]] = Types.Resources.Amounts[i]
) for i in [0...Types.Resources.Names.length]

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
  window['Properties'] = Properties
