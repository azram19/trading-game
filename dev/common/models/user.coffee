_ ?= require( 'underscore' )._
Backbone ?= require( 'backbone' )

class User extends Backbone.Model
  defaults:
    highscore: 0

  initialize: () ->
    self = @
    @app = @options.app
    @id = @options.id

    #connect to the database and check if the user alread exists
    app.connectDb ( err, db ) =>
      db.collection 'users', ( err, users ) =>
        assert.equal null, err

        users.findOne query, ( err, user) =>
          assert.equal null, err

          #new user, insert into databas
          if user?
            @set registerTime, Date()

          #user exists retrieve his data
          else

        db.close()
