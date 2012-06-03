class Uid

    constructor: ->
        @uid = -1

    get: ->
        ++@uid
        @uid

if module? and module.exports
  exports = module.exports = new Uid()
else
  window['Uid'] = new Uid()
