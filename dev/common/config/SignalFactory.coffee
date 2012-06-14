S = {}
if require?
    _ = require('underscore')._
    S.Types = require './Types'
    S.Signal = require '../objects/Signal'
else
    _ = window._
    S.Signal = window.S.Signal
    S.Types = window.S.Types

class SignalFactory

    constructor: ->
        @builders = {}
        @builders[S.Types.Entities.Signal] = (id, args) =>
            events = args[0]
            strength = args[1]
            type = args[2]
            source = args[3]
            name = 'Signal' + id
            st = new S.Signal(events, strength, type, source)
            signal = _.extend st, {'name': name, 'id': id}

    build: ( kind, args... ) ->
        if not kind
            console.error "kind is undefined"
        if not _.isFunction @builders[kind]
            throw Error kind + " is not a valid Entity type"

        uid = _.uniqueId()
        @builders[kind](uid, args)

if module? and module.exports
  exports = module.exports = new SignalFactory()
else
  window.S.SignalFactory = new SignalFactory()
