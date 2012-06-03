#node.js requirements
if require?
  _ = require 'underscore'
  Backbone = require 'backbone'

class User extends Backbone.Model
  defaults:
    highscore: 0

  initialize: () ->
    #@app = @options.app
    #@id = @options.id
    @resources = {}

    #connect to the database and check if the user alread exists
    #app.connectDb ( err, db ) =>
      #db.collection 'users', ( err, users ) =>
        #assert.equal null, err

        #users.findOne query, ( err, user) =>
          #assert.equal null, err

          ##new user, insert into databas
          #if user?
            #@set registerTime, Date()

          ##user exists retrieve his data
          #else

        #db.close()

  addResource: ( s ) ->
    @resources[s.type] ?= 0
    @resources[s.type] += s.strength

  spendResources: ( t, x ) ->
    if @resources[t] > x
      @resources[t] -= x
      true
    else
      false

if module? and module.exports
  exports = module.exports = User
else
  window['User'] = User
