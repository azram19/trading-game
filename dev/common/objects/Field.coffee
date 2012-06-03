class Field
    platform: {}
    resource: {}

if module? and module.exports
  exports = module.exports = Field
else
  window['Field'] = Field
