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
            st = new S.ObjectState()
            state = _.extend st, @deepClone(S.Properties.platform, true)
            state = _.extend state, {'name': name, 'id': id, 'owner': owner, 'type': S.Types.Entities.Platforms.Normal}
            object = new S.GameObject new S.PlatformBehaviour(events), state

        @builders[S.Types.Entities.Platforms.HQ] = (id, args) =>
            events = args[0]
            owner = args[1]
            name = 'HQ' + id
            st = new S.ObjectState()
            state = _.extend st, @deepClone(S.Properties.HQ, true)
            state = _.extend state, {'name': name, 'id': id, 'owner': owner}
            object = new S.GameObject new S.HQBehaviour(events), state

        @builders[S.Types.Entities.Channel] = (id, args) =>
            events = args[0]
            owner = args[1]
            name = 'Channel' + id
            st = new S.ObjectState()
            state = _.extend st, @deepClone(S.Properties.channel, true)
            state = _.extend state, {'name': name, 'id': id, 'owner': owner}
            object = new S.GameObject new S.ChannelBehaviour(events), state

        @builders[S.Types.Entities.Player] = (id, args) =>
            userId = args[0]
            st = new S.Player()
            player = _.extend st, @deepClone( S.Properties.player, true )
            name = 'Player_' + id
            _.extend player, {'name': name, 'id': id, 'userId': userId}

        #@builders[Types.Entities.Signal] = (id, args) =>
            #strength = args[0]
            #type = args[1]
            #source = args[2]
            #name = 'Signal' + id
            #signal = _.extend new Signal(strength, type, source), {'name': name, 'id': id}

        @builders[S.Types.Resources.Food] = (id, args) =>
            events = args[0]
            owner = args[1]
            name = 'Food' + id
            st = new S.ObjectState()
            state = _.extend st, @deepClone(S.Properties.resource, true)

            state = _.extend state, {
                'name': name,
                'id': id,
                'owner': owner,
                'type': S.Types.Resources.Food
            }

            object = new S.GameObject new S.ResourceBehaviour(S.Types.Resources.Food, events), state

        @builders[S.Types.Resources.Gold] = (id, args) =>
            events = args[0]
            owner = args[1]
            name = 'Gold' + id
            st = new S.ObjectState()
            state = _.extend st, @deepClone(S.Properties.resource, true)

            state = _.extend state, {
                'name': name,
                'id': id,
                'owner': owner,
                'type': S.Types.Resources.Gold
            }

            object = new S.GameObject new S.ResourceBehaviour(S.Types.Resources.Gold, events), state

        @builders[S.Types.Resources.Resources] = (id, args) =>
            events = args[0]
            owner = args[1]
            name = 'Resources' + id
            st = new S.ObjectState()
            state = _.extend st, @deepClone(S.Properties.resource, true)

            state = _.extend state, {
                'name': name,
                'id': id,
                'owner': owner,
                'type': S.Types.Resources.Resources
            }

            object = new S.GameObject new S.ResourceBehaviour(S.Types.Resources.Resources, events), state

        _.extend @builders, S.SignalFactory.builders

    build: ( kind, args... ) ->
        if not kind
            console.error "kind is undefined"
        if not _.isFunction @builders[kind]
            throw Error kind + " is not a valid Entity type"

        uid = _.uniqueId()
        @builders[kind](uid, args)

    deepClone: (obj, deep) ->
      return obj  if not _.isObject(obj) or _.isFunction(obj)
      return new Date(obj.getTime())  if _.isDate(obj)
      return new RegExp(obj.source, obj.toString().replace(/.*\//, ""))  if _.isRegExp(obj)
      isArr = (_.isArray(obj) or _.isArguments(obj))
      if deep
        func = (memo, value, key) =>
          if isArr
            memo.push @deepClone(value, true)
          else
            memo[key] = @deepClone(value, true)
          memo

        _.reduce obj, func, (if isArr then [] else {})
      else
        (if isArr then slice.call(obj) else _.extend({}, obj))

if module? and module.exports
  exports = module.exports = new ObjectFactory()
else
  window.S.ObjectFactory = new ObjectFactory()
