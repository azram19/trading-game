if require?
    _ = require('underscore')._
    Properties = require './Properties'
    Types = require './Types'
    User = require '../models/user'
    GameObject = require '../objects/object'
    ObjectState = require '../objects/state'
    HQBehaviour = require '../behaviours/HQBehaviour'
    ChannelBehaviour = require '../behaviours/ChannelBehaviour'
    PlatformBehaviour = require '../behaviours/PlatformBehaviour'
    ResourceBehaviour = require '../behaviours/ResourceBehaviour'

class ObjectFactory

    constructor: ->
        @builders = {}
        @builders[Types.Entities.Platform] = (args) =>
            owner = args[0]
            type = args[1]
            name = 'Platform' + @uid
            state = _.extend new ObjectState(), _.clone(Properties.platform)
            state = _.extend state, {'name': name, 'id': @uid, 'owner': owner}
            object = new GameObject new PlatformBehaviour(type), state

        @builders[Types.Entities.HQ] = (args) =>
            owner = args[0]
            name = 'HQ' + @uid
            state = _.extend new ObjectState(), _.clone(Properties.HQ)
            state = _.extend state, {'name': name, 'id': @uid, 'owner': owner}
            object = new GameObject new HQBehaviour(), state

        @builders[Types.Entities.Channel] = (args) =>
            owner = args[0]
            name = 'Channel' + @uid
            state = _.extend new ObjectState(), _.clone(Properties.channel)
            state = _.extend state, {'name': name, 'id': @uid, 'owner': owner}
            object = new GameObject new ChannelBehaviour(), state

        @builders[Types.Entities.User] = (args) =>
            user = _.extend new User(), _.clone( Properties.user )
            name = 'User' + @uid
            _.extend user, {'name': name, 'id': @uid}

        @builders[Types.Entities.Signal] = (args) =>
            strength = args[0]
            type = args[1]
            source = args[2]
            name = 'Signal' + @uid
            signal = _.extend new Signal(strength, type, source), _.clone(Properties.signal)
            signal = _.extend signal, {'name': name, 'id': @uid}

        @builders[Types.Resources.Metal] = (args) =>
            owner = args[0]
            name = 'Metal' + @uid
            state = _.extend new ObjectState(), _.clone(Properties.resource)
            state = _.extend state, {'name': name, 'id': @uid, 'owner': owner}
            object = new GameObject new ResourceBehaviour(Types.Resources.Names[0]), state

        @builders[Types.Resources.Tritium] = (args) =>
            owner = args[0]
            name = 'Tritium' + @uid
            state = _.extend new ObjectState(), _.clone(Properties.resource)
            state = _.extend state, {'name': name, 'id': @uid, 'owner': owner}
            object = new GameObject new ResourceBehaviour(Types.Resources.Names[1]), state
        @uid = -1

    build: ( kind, args... ) ->
        if not kind
            console.error "kind is undefined"
        if not _.isFunction @builders[kind]
            throw Error kind + " is not a valid Entity type"

        @uid++
        @builders[kind](args)


if module? and module.exports
  exports = module.exports = new ObjectFactory()
else
  root['ObjectFactory'] = new ObjectFactory()
