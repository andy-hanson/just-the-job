(require 'source-map-support').install()

{ exec } = require 'child_process'

type = (val, type) ->
	###
	Asserts that the value is of the given type.
	###
	if val == null
		throw new Error "Does not exist of type #{type.name}"
	asObject = (-> @).call val
	unless asObject instanceof type
		throw new Error \
			"Expected #{asObject} (a #{asObject.constructor.name}) to be a #{type.name}"

execCommand = (command) ->
	###
	Generates a function that takes `after` as input,
	runs the command, prints the results, then runs `after`.
	###
	(after) ->
		exec command, (err, stdout, stderr) ->
			out = stdout + stderr
			unless out == ''
				if out[out.length - 1] == '\n'
					console.log out.slice 0, out.length - 1
				else
					console.log out
			throw err if err?
			after()

class StringMap
	###
	Maps names to values.
	###
	constructor: ->
		@_data = {}
	has: (name) ->
		Object.prototype.hasOwnProperty.call @_data, name
	get: (name) ->
		if @has name
			@_data[name]
		else
			throw new Error "No entry #{name}"
	set: (name, value) ->
		@_data[name] = value

class StringSet
	###
	A set of names.
	###
	constructor: ->
		@_data = {}
	has: (name) ->
		Object.prototype.hasOwnProperty.call @_data, name
	add: (name) ->
		@_data[name] = yes
	delete: (name) ->
		delete @_data[name]

class Job
	###
	A thing that one might want to have done.
	###
	constructor: (@name, @dependencies, @run) ->

class JustTheJob
	###
	just-the-job calls the provided function on an instance of this class.
	###

	constructor: ->
		###
		Creates a new name-job map
		###
		@jobs = new StringMap

	hasJob: (name) ->
		###
		Whether a job of the given name has been defined.
		###
		type name, String
		@jobs.has name

	_toFunction: (run) ->
		if run instanceof Function
			run
		else
			type run, String
			execCommand run

	_args: (args) ->
		name = args[0]
		description = ''
		dependencies = []
		run = (after) -> after()

		switch args.length
			when 2
				if args[1] instanceof Array
					dependencies = args[1]
				else
					run = args[1]
			when 3
				if args[1] instanceof Array
					# @job dependencies, run
					dependencies = args[1]
					run = args[2]
				else
					description = args[1]
					if args[2] instanceof Array
						dependencies = args[2]
					else
						run = args[2]
			when 4
				description = args[1]
				dependencies = args[2]
				run = args[3]

		type name, String
		type description, String
		type dependencies, Array
		run = @_toFunction run

		name: name
		description: description
		dependencies: dependencies
		run: run

	job: ->
		###
		Creates a new job with the given name, dependencies, and task.

		* name - Name of the job.
		* description - (Optional) provides Cake a description of the job.
		* dependencies - (Optional) Array of jobs that must be done before this one.
		* run - A shell comand, or a continuation-passing function.
		###

		{ name, description, dependencies, run } = @_args arguments

		if @hasJob name
			throw new Error "Already exists job #{name}"

		@jobs.set name, new Job name, dependencies, run

	task: ->
		###
		`task name, [description,] dependencies, run`
		Creates a job and registers as a task (for use in Cakefiles).

		* name - Name of the job.
		* dependencies - Array of jobs that must be done before this one.
		* run - A shell comand, or a continuation-passing function.
		###

		{ name, description } = @_args arguments
		@job.apply @, arguments

		global.task name, description, =>
			@do name

	_getJob: (name) ->
		###
		The job with the given name.
		###
		type name, String
		unless @hasJob name
			throw new Error "No job #{name}"
		@jobs.get name

	_getJobList: (name) ->
		###
		An ordered list of jobs, ending in the job of the given name.

		Uses the 2nd algorithm from en.wikipedia.org/wiki/Topological_sort
		###
		type name, String

		# Jobs the dependencies are currently being found for.
		temps = new StringSet
		# Jobs that have been satisfied already.
		perms = new StringSet

		toDo = []

		visit = (jobName) =>
			if temps.has jobName
				throw new Error "#{jobName} depends on itself!"
			unless perms.has jobName
				temps.add jobName
				job = @_getJob jobName
				job.dependencies.forEach visit
				temps.delete jobName
				perms.add jobName

				unless (toDo.indexOf job) == -1
					throw new Error "Algorithm sucks #{toDo.indexOf job}"

				toDo.push job

		visit name

		toDo

	getRunner: (name, after) ->
		###
		Generates a function that runs the job, then runs after (if it exists).

		* name - Name of the job.
		* after - (Optional) Function to run after the job.
		###
		unless after?
			after = -> null

		doAll =  after
		(@_getJobList name).reverse().forEach (job) ->
			doAllSoFar = doAll
			doAll = -> job.run doAllSoFar
		doAll

	do: (name, after) ->
		###
		Runs the job of the given name.

		* name - Name of the job.
		* after - (Optional) Function to run after the job.
		###
		type name, String
		(@getRunner name, after)()


module.exports = (fun) ->
	###
	Calls the function with `this` as a new JustTheJob.
	###
	type fun, Function
	fun.call new JustTheJob
