_ ?= require( 'underscore' )._
Backbone ?= require( 'backbone' )

class User extends Backbone.Model
  initialize: () ->

if exports?
  if module? and module.exports
    exports = module.exports = User
else 
  root['User'] = User
