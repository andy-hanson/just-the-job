Just The Job is a way to easily write Cake tasks.

Let's look at an example:

```coffeescript
require('just-the-job') ->
	@job 'say-hi', 'echo hi there'

	@task 'my-job', ['say-hi'], (after) ->
		console.log 'just doing my job'
		after()
```

The example creates both a job and a cake task.
The only difference is that tasks show up in the usage when 'cake' is run alone.

They share the same syntax:

```coffeescript
@job 'name', «'description',» «['depends-on-these', ...]», run
```

where `«arg»` indicates an optional argument.

The description becomes part of cake's usage string.
The dependencies are an unordered set of jobs that must be run before this one.
If `run` is a String, the job is a console command.
If `run` is a Function, it should be written in continuation-passing style;
the job to be performed after it is passed in as the argument. (See the example.)

These are instance methods;
just-the-job drops you into a JustTheJob object which contains
all of your jobs (so, calling just-the-job twice produces two separate job sets).
It also has these methods:

* `@getRunner name, <<after>>`
	Produces a continuation-passing function to run the job (and its dependencies).
	If `after` is present, the function calls it at the end.

* `@do name, <<after>>`
	Runs the result of `@getRunner`.
