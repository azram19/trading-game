###
load dependencies for server and client
coffee declraes all varialbes in
###
S = {}
if require? #server
    _ = require('underscore')._
    S.Properties = require './Properties'
    S.Types = require './Types'
    S.Player = require '../models/Player'
    S.GameObject = require '../objects/GameObject'
    S.SignalFactory = require './SignalFactory'
    S.ObjectState = require '../objects/ObjectState'
    S.HQBehaviour = require '../behaviours/HQBehaviour'
    S.ChannelBehaviour = require '../behaviours/ChannelBehaviour'
    S.PlatformBehaviour = require '../behaviours/PlatformBehaviour'
    S.ResourceBehaviour = require '../behaviours/ResourceBehaviour'
else #client
    _ = window._
    S.Properties = window.S.Properties
    S.Types = window.S.Types
    S.Player = window.S.Player
    S.GameObject = window.S.GameObject
    S.SignalFactory = window.S.SignalFactory
    S.ObjectState = window.S.ObjectState
    S.HQBehaviour = window.S.HQBehaviour
    S.ChannelBehaviour = window.S.ChannelBehaviour
    S.PlatformBehaviour = window.S.PlatformBehaviour
    S.ResourceBehaviour = window.S.ResourceBehaviour

class ObjectFactory
  
    # change those crazy clone, extend to _.defaults
    constructor: ->
        @builders = {}
        @builders[S.Types.Entities.Platforms.Normal] = (id, args) =>
            events = args[0]
            owner = args[1]
            name = 'Platform' + id
            state = _.extend new S.ObjectState(), _.clone(S.Properties.platform)
            state = _.extend state, {'name': name, 'id': id, 'owner': owner, 'type': S.Types.Entities.Platforms.Normal}
            object = new S.GameObject new S.PlatformBehaviour(events), state

        @builders[S.Types.Entities.Platforms.HQ] = (id, args) =>
            events = args[0]
            owner = args[1]
            name = 'HQ' + id
            state = _.extend new S.ObjectState(), _.clone(S.Properties.HQ)
            state = _.extend state, {'name': name, 'id': id, 'owner': owner}
            object = new S.GameObject new S.HQBehaviour(events), state

        @builders[S.Types.Entities.Channel] = (id, args) =>
            events = args[0]
            owner = args[1]
            name = 'Channel' + id
            state = _.extend new S.ObjectState(), _.clone(S.Properties.channel)
            state = _.extend state, {'name': name, 'id': id, 'owner': owner}
            object = new S.GameObject new S.ChannelBehaviour(events), state

        @builders[S.Types.Entities.Player] = (id, args) =>
            player = _.extend new S.Player(), _.clone( S.Properties.player )
            name = 'Player_' + id
            _.extend player, {'name': name, 'id': id}

        #@builders[Types.Entities.Signal] = (id, args) =>
            #strength = args[0]
            #type = args[1]
            #source = args[2]
            #name = 'Signal' + id
            #signal = _.extend new Signal(strength, type, source), {'name': name, 'id': id}

        @builders[S.Types.Resources.Metal] = (id, args) =>
            events = args[0]
            owner = args[1]
            name = 'Metal' + id
            state = _.extend new S.ObjectState(), _.clone(S.Properties.resource)
            state = _.extend state, {'name': name, 'id': id, 'owner': owner, 'type': S.Types.Resources.Metal}
            object = new S.GameObject new S.ResourceBehaviour(S.Types.Resources.Metal, events), state

        @builders[S.Types.Resources.Tritium] = (id, args) =>
            events = args[0]
            owner = args[1]
            name = 'Tritium' + id
            state = _.extend new S.ObjectState(), _.clone(S.Properties.resource)
            state = _.extend state, {'name': name, 'id': id, 'owner': owner, 'type': S.Types.Resources.Tritium}
            object = new S.GameObject new S.ResourceBehaviour(S.Types.Resources.Tritium, events), state

        _.extend @builders, S.SignalFactory.builders

    build: ( kind, args... ) ->
        if not kind
            console.error "kind is undefined"
        if not _.isFunction @builders[kind]
            throw Error kind + " is not a valid Entity type"

        uid = _.uniqueId()
        @builders[kind](uid, args)


if module? and module.exports
  exports = module.exports = new ObjectFactory()
else
  window.S.ObjectFactory = new ObjectFactory()
