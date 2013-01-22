# Provides wrapper around console.log which allows for customization and log
# level threshold

S = {}
if require?
  _ = require('underscore')._
  colors = require 'colors'
else
  _ = window._

class Logger

  constructor: (opts) ->
    opts = opts or {}
    @level = if opts.level? then opts.level else 3
    @enabled = false isnt opts.enabled
    @name = if opts.name? then opts.name else 'Global'
    @browser = require?

    @levels =
      trace: 'grey'
      debug: 'cyan'
      info: 'green'
      warn: 'yellow'
      error: 'red'

    @maxLevelLength = _.max(@levels, (v, k) -> k.length).length

    # Generate methods
    _.each @levels, (color, name) =>
      @[name] = ->
        @log.apply @, [name].concat _.toArray(arguments)

  pad: (str) ->
    if str.length < @maxLevelLength
      return str + new Array(@maxLevelLength - str.length + 1).join ' '

    str

  prep: (numb, n) ->
    ("000" + numb)[-n..]; # works for n <= 3

  getDate: ->
      d = new Date()
      d.toLocaleTimeString() + '.' + @prep d.getMilliseconds(), 3

  prepareMessage: (type) ->
    index = _.keys(@levels).indexOf type
    levelColor = _.values(@levels)[index]

    if @browser
      [
        @getDate().grey
        '-'[levelColor]
        @pad(type)[levelColor].bold
        '-'[levelColor]
        @name.bold
        '-'[levelColor]
      ]
    else
      [ @getDate()
        '-'
        @pad(type)
        '-'
        @name
        '-'
      ]

  log: (type) ->
    index = _.keys(@levels).indexOf type

    if index > @level or not @enabled
      return @

    console.log.apply console,
      @prepareMessage(type).concat _.toArray(arguments)[1..]

    @

defaults =
  name: 'Global'
  level: 3
  enabled: true

log =
  defaults: (config) ->
    _.extend defaults, config
  createLogger: (config) ->
    defCopy = _.clone defaults
    _.extend defCopy, config
    new Logger defCopy

if module? and module.exports
  exports = module.exports = log
else
  window.S.Logger = log