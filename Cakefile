{ exec } = require 'child_process'

execHandle = (after) ->
	(err, stdout, stderr) ->
		out = stdout + stderr
		if out != ''
			console.log out
		throw err if err?
		after()

task 'all', 'Description', ->
	cmd =
		'coffee --compile --bare --map --output js source'
	exec cmd, execHandle ->
		exec 'bin/test', execHandle ->
			null
			#console.log 'done'
