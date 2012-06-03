if require?
    _ = require('underscore')._
    Properties = require './Properties'
    Types = require './Types'
    User = require '../models/User'
    Uid = require './Uid'
    GameObject = require '../objects/GameObject'
    SignalFactory = require './SignalFactory'
    ObjectState = require '../objects/ObjectState'
    HQBehaviour = require '../behaviours/HQBehaviour'
    ChannelBehaviour = require '../behaviours/ChannelBehaviour'
    PlatformBehaviour = require '../behaviours/PlatformBehaviour'
    ResourceBehaviour = require '../behaviours/ResourceBehaviour'
else
    _ = window._
    Properties = window.Properties
    Types = window.Types
    User = window.User
    Uid = window.Uid
    GameObject = window.GameObject
    SignalFactory = window.SignalFactory
    ObjectState = window.ObjectState
    HQBehaviour = window.HQBehaviour
    ChannelBehaviour = window.ChannelBehaviour
    PlatformBehaviour = window.PlatformBehaviour
    ResourceBehaviour = window.ResourceBehaviour

class ObjectFactory

    constructor: ->
        @builders = {}
        @builders[Types.Entities.Platform] = (id, args) =>
            owner = args[0]
            type = args[1]
            name = 'Platform' + id
            state = _.extend new ObjectState(), _.clone(Properties.platform)
            state = _.extend state, {'name': name, 'id': id, 'owner': owner}
            object = new GameObject new PlatformBehaviour(type), state

        @builders[Types.Entities.HQ] = (id, args) =>
            owner = args[0]
            name = 'HQ' + id
            state = _.extend new ObjectState(), _.clone(Properties.HQ)
            state = _.extend state, {'name': name, 'id': id, 'owner': owner}
            object = new GameObject new HQBehaviour(), state

        @builders[Types.Entities.Channel] = (id, args) =>
            owner = args[0]
            name = 'Channel' + id
            state = _.extend new ObjectState(), _.clone(Properties.channel)
            state = _.extend state, {'name': name, 'id': id, 'owner': owner}
            object = new GameObject new ChannelBehaviour(), state

        @builders[Types.Entities.User] = (id, args) =>
            user = _.extend new User(), _.clone( Properties.user )
            name = 'User' + id
            _.extend user, {'name': name, 'id': id}

        #@builders[Types.Entities.Signal] = (id, args) =>
            #strength = args[0]
            #type = args[1]
            #source = args[2]
            #name = 'Signal' + id
            #signal = _.extend new Signal(strength, type, source), {'name': name, 'id': id}

        @builders[Types.Resources.Metal] = (id, args) =>
            owner = args[0]
            name = 'Metal' + id
            state = _.extend new ObjectState(), _.clone(Properties.resource)
            state = _.extend state, {'name': name, 'id': id, 'owner': owner}
            object = new GameObject new ResourceBehaviour(Types.Resources.Names[0]), state

        @builders[Types.Resources.Tritium] = (id, args) =>
            owner = args[0]
            name = 'Tritium' + id
            state = _.extend new ObjectState(), _.clone(Properties.resource)
            state = _.extend state, {'name': name, 'id': id, 'owner': owner}
            object = new GameObject new ResourceBehaviour(Types.Resources.Names[1]), state

        console.log "SF"
        console.debug SignalFactory
        _.extend @builders, SignalFactory.builders

    build: ( kind, args... ) ->
        if not kind
            console.error "kind is undefined"
        if not _.isFunction @builders[kind]
            throw Error kind + " is not a valid Entity type"

        @builders[kind](Uid.get(), args)


if module? and module.exports
  exports = module.exports = new ObjectFactory()
else
  window['ObjectFactory'] = new ObjectFactory()
