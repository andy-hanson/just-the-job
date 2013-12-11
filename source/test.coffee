(require 'source-map-support').install()

depends = require './index'

console.log 'Should print 3 2 1'

depends ->
	@job '1', ['3', '2'], (after) ->
		console.log '1'
		after()
	@execJob '2', ['3'], 'echo 2'
	@job '3', [], (after) ->
		console.log '3'
		after()
	@do '1'
