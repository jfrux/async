<cfscript>
	async = new async();
	console = new foundry.lib.console();

	endpoints = [
		"https://github.com/caolan/async",
		"https://github.com/joshuairl/mkdirp",
		"https://github.com/joshuairl/fpm-test-module",
		"https://github.com/foundrycf/foundry",
		"https://github.com/foundrycf/fpm"
	];

	doneEndpoints = function() {
		console.print("done with endpoints");
	};

	// async.forEach(endpoints,function (endpoint, next) {
	//     console.print(endpoint);
	//     next();
	//   },
	//   doneEndpoints
	// );

	async.filter(endpoints,function(endpoint, next) {
		console.print("test");
		//next();
	},doneEndpoints);
</cfscript>