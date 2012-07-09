_ = require('underscore')._

class Logger

  constructor: (opts) ->
    opts = opts or {}
    @colors = false isnt opts.colors
    @level = if opts.level? then opts.level else 3
    @enabled = true

    # Colors for log levels.
    @colorCodes = [
      31
      33
      36
      35
      90
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
      [
        if @colors then '  \x1B[' + @colorCodes[index] + 'm' + @pad type + ' -\x1B[39m'
        else type +  ':'
      ].concat _.toArray(arguments)[1..]

    @

module.exports = Logger