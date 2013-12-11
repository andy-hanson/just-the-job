{ exec } = require 'child_process'

type = (val, type) ->
	if val == null
		throw new Error "Does not exist of type #{type.name}"
	asObject = (-> @).call val
	unless asObject instanceof type
		throw new Error \
			"Expected #{obj} (a #{obj.constructor.name}) to be a #{type.name}"

hop = (obj, name) ->
	Object.prototype.hasOwnProperty.call obj, name

runCommand = (command) ->
	(after) ->
		exec command, (err, stdout, stderr) ->
			out = stdout + stderr
			console.log out unless out == ''
			throw err if err?
			after()

class Job
	constructor: (@name, @dependencies, @run) ->

class Depends
	constructor: ->
		# name -> job
		@jobs = Map()

	hasJob: (name) ->
		type name, String
		#hop @jobs, name
		@jobs.has name

	job: (name, dependencies, run) ->
		type name, String
		type dependencies, Array
		type run, Function

		if @hasJob name
			throw new Error "Already exists job #{name}"

		@jobs.set name, new Job name, dependencies, run

	execJob: (name, dependencies, command) ->
		@job name, dependencies, runCommand command

	execTask: (name, description, dependencies, command) ->
		@task name, description, dependencies, runCommand command

	task: (name, description, dependencies, run) ->
		type name, String
		type description, String
		type dependencies, Array
		type run, Function

		# cake task
		@job name, dependencies, run
		global.task name, description, =>
			@do name

	getJob: (name) ->
		type name, String
		unless @hasJob name
			throw new Error "No job #{name}"
		@jobs.get name

	getJobList: (name) ->
		type name, String
		# 2nd algorithm from http://en.wikipedia.org/wiki/Topological_sort

		temps = Set() # Jobs the dependencies are currently being found for.
		perms = Set() # Jobs that have been satisfied already.

		toDo = []

		visit = (jobName) =>
			if temps.has jobName
				throw new Error "#{job} depends on itself!"
			unless perms.has jobName
				job = @getJob jobName
				job.dependencies.forEach visit
				temps.delete jobName
				perms.add jobName

				unless (toDo.indexOf job) == -1
					throw new Error "Algorithm sucks #{toDo.indexOf job}"

				toDo.push job

		visit name

		toDo

	getRunner: (name) ->
		doAll =  -> null
		(@getJobList name).reverse().forEach (job) ->
			doAllSoFar = doAll
			doAll = -> job.run doAllSoFar
		doAll

	do: (name) ->
		type name, String
		(@getRunner name)()


module.exports = (fun) ->
	type fun, Function
	fun.call new Depends
