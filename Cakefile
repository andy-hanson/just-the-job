{ exec } = require 'child_process'

run = (command, after) ->
	exec command, (err, stdout, stderr) ->
		out = stdout + stderr
		console.log out unless out == ''
		throw err if err?
		after()

task 'all', 'Compile, lint, doc, and run', ->
	run 'coffee --compile --bare --map --output js source', ->
		run 'coffeelint -f source/coffeelint-config.json source/*.coffee', ->
			run 'coffeedoc --output doc --hide-private source', ->
				run 'node js/test', ->
					null
