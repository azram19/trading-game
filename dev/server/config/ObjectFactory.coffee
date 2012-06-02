if require?
    Properties = require './Properties'
    Types = require './Types'
    GameObject = require '../objects/object'
    ObjectState = require '../objects/state'
    HQBehaviour = require '../objects/behaviours/HQBehaviour'
    ChannelBehaviour = require '../objects/behaviours/ChannelBehaviour'
    PlatformBehaviour = require '../objects/behaviours/PlatformBehaviour'
    ResourceBehaviour = require '../objects/behaviours/ResourceBehaviour'

class ObjectFactoy

    constructor: ->

    build: ( kind ) ->


if module? and module.exports
  exports = module.exports = ObjectFactory
else
  root['ObjectFactory'] = ObjectFactory
