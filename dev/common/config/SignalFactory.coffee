if require?
    _ = require('underscore')._
    Types = require './Types'
    Uid = require './Uid'
    Signal = require '../objects/signal'

class SignalFactory

    constructor: ->
        @builders = {}
        @builders[Types.Entities.Signal] = (id, args) =>
            strength = args[0]
            type = args[1]
            source = args[2]
            name = 'Signal' + id
            signal = _.extend new Signal(strength, type, source), {'name': name, 'id': id}

    build: ( kind, args... ) ->
        if not kind
            console.error "kind is undefined"
        if not _.isFunction @builders[kind]
            throw Error kind + " is not a valid Entity type"

        @builders[kind](Uid.get(), args)

if module? and module.exports
  exports = module.exports = new SignalFactory()
else
  window['SignalFactory'] = new SignalFactory()
