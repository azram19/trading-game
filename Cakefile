fs = require 'fs'

{print} = require 'sys'
{spawn} = require 'child_process'

build = ( clbck ) ->
  coffee = spawn 'coffee', ['-c', '-o', 'build', 'dev']
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?() if code is 0

task 'build', 'Build build/ from dev/', ->
  build()

task 'watch', 'Watch dev/ for changes', ->
    coffee = spawn 'coffee', ['-w', '-c', '-o', 'build', 'dev']
    coffee.stderr.on 'data', (data) ->
      process.stderr.write data.toString()
    coffee.stdout.on 'data', (data) ->
      print data.toString()
