# Provides wrapper around console.log which allows for customization and log
# level threshold

S = {}
if requrire?
  _ = require('underscore')._
else
  _ = window._

class Logger

  constructor: (opts) ->
    opts = opts or {}
    @colors = false isnt opts.colors
    @level = if opts.level? then opts.level else 3
    @enabled = false isnt opts.enabled
    @name = if opts.name? then opts.name else 'Global'
    @browser = require?

    # Colors for log levels.
    @colorCodes = [
      31 # Red
      33 # Yellow
      32 # Cyan
      35 # Green
      90 # Grey
    ]

    @levels = [
      'error'
      'warn'
      'info'
      'debug'
      'trace'
    ]

    @maxLevelLength = _.max(@levels, (v) -> v.length).length
    # Generate methods
    _.each @levels, (name) =>
      @[name] = ->
        @log.apply @, [name].concat _.toArray(arguments)

  pad: (str) ->
    if str.length < @maxLevelLength
      return str + new Array(@maxLevelLength - str.length + 1).join ' '

    str

  log: (type) ->
    index = @levels.indexOf type

    if index > @level or not @enabled
      return @

    console.log.apply console,
      [ '[' + @name + '] -'
        if @colors and @browser then '\x1B[' + @colorCodes[index] + 'm' + @pad(type) + ' -\x1B[39m'
        else type + ':'
      ].concat _.toArray(arguments)[1..]

    @

defaults =
  name: 'Global'
  level: 3
  colors: true
  enabled: true

publicApi =
  defaults: (config) ->
    _.extend defaults, config
  Logger: (config) ->
    new Logger (config || defaults)

if module? and module.exports
  exports = module.exports = publicApi
else
  window.S.Logger = publicApi