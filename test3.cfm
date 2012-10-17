<!---
	Start a CFScript block. Closures can only be used inside
	of CFScript due to the syntax required to define them.
--->
<cfscript>
	testThread = getPageContext().getThread();
	writeDump(var=testThread.getName());
	writeDump(var=testThread,abort=true);
	// ------------------------------------------------------ //
	// ------------------------------------------------------ //
	// ------------------------------------------------------ //
	// ------------------------------------------------------ //


	// Create an instance of event emitter. This will have the
	// publication and subscription methods for:
	//
	// - on()
	// - off()
	// - trigger()
	console = new foundry.lib.console();
	evented = new foundry.lib.emitter();


	// Run a thread an pass in the event emitter. This will allow the
	// the thread to announce events during its execution.
	thread
		name = "eventedThread"
		action = "run"
		beacon = evented
		{

		// Sleep this thread immediately to let the code AFTER the
		// thread run and bind to the events.
		sleep( 100 );

		// Trigger start event.
		beacon.emit(
			"threadStarted",
			"The thread has started!"
		);

		sleep( 100 );

		// Trigger end event.
		beacon.emit(
			"threadEnded",
			"The thread has ended!"
		);

	}


	// ------------------------------------------------------ //
	// ------------------------------------------------------ //


	// Before we check the valid event emitting, we want to check to
	// make sure that the UNBIND feature works.
	tempCallback = function( message ){
		console.log( "This should never be called." );
	};

	// Bind and UNBIND the callback. We want to make sure that it
	// will NOT get called for the given event types.
	evented.on( "threadEnded", tempCallback );
	evented.removeListener('threadEnded', tempCallback);

	// ------------------------------------------------------ //
	// ------------------------------------------------------ //


	// Bind to the "Start" event on the thread.
	evented.on(
		"threadStarted",
		function( message ){

			console.log( message);

		}
	);

	// Bind to the "End" event on the thread.
	evented.on(
		"threadEnded",
		function( message ){

			console.log( message);

		}
	);


	// ------------------------------------------------------ //
	// ------------------------------------------------------ //


	// Halt the page until the thread has finished execution. This
	// will cause the events to be triggered BEFORE this page has
	// finished running.
	thread action = "join";

	// Debug threads.
	console.log( serialize(cfthread) );


</cfscript>