if require?
    _ = require('underscore')._
    Types = require './Types'
    Signal = require '../objects/Signal'
else
    _ = window._
    Signal = window.Signal
    Types = window.Types

class SignalFactory

    constructor: ->
        @builders = {}
        @builders[Types.Entities.Signal] = (id, args) =>
            events = args[0]
            strength = args[1]
            type = args[2]
            source = args[3]
            name = 'Signal' + id
            signal = _.extend new Signal(events, strength, type, source), {'name': name, 'id': id}

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
  window['SignalFactory'] = new SignalFactory()
