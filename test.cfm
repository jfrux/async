<cfscript>
	async = new async_sesame();
	console = new foundry.lib.console();

	endpoints = [
		"https://github.com/caolan/async",
		"https://github.com/joshuairl/mkdirp",
		"https://github.com/joshuairl/fpm-test-module",
		"https://github.com/foundrycf/foundry",
		"https://github.com/foundrycf/fpm"
	];


	doneEndpoints = function(err) {
		if(structKeyExists(arguments,'err')) {
			console.error(err.message);
		}

		console.print("completed all!");
	};

	console.log("async.forEach()");
	async._eachParallel(endpoints,function (endpoint, next) {
		console.info("#endpoint#");
	}	);


	// console.log("async.forEachSeries()");
	// async.forEachSeries(endpoints,function(endpoint, next) {
	// 	console.print(endpoint);
	// 	next();
	// },doneEndpoints);


	// console.log("async.forEachLimit()");
	// async.forEachLimit(endpoints,10,function(endpoint, next) {
	// 	console.print(endpoint);
	// 	next();
	// },doneEndpoints);
</cfscript>