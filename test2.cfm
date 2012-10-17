<!---
	Start a CFScript block. Closures can only be used inside
	of CFScript due to the syntax required to define them.
--->
<cfscript>
	console = new foundry.lib.console();

	// I accept N thread instances and a callback (the last
	// argument). The callback is invoked when each one of the given
	// threads has completed execution (success or failure). The
	// thread object is echoed back in the callback arguments.
	


	// ------------------------------------------------------ //
	// ------------------------------------------------------ //
	// ------------------------------------------------------ //
	// ------------------------------------------------------ //


	// Launch a thread - remember this is an ASYNCHRONOUS operation.
	thread
		name = "thread1"
		action = "run" {

		// Sleep the thread breifly.
		sleep( randRange( 10, 100 ) );

	}


	// Launch a thread - remember this is an ASYNCHRONOUS operation.
	thread
		name = "thread2"
		action = "run" {

		// Sleep the thread breifly.
		sleep( randRange( 10, 100 ) );

	}


	// Launch a thread - remember this is an ASYNCHRONOUS operation.
	thread
		name = "thread3"
		action = "run" {

		// In this one, let's throw an error to show that this works
		// with failed threads as well as successful one.
		//
		// NOTE: Since this is an asynchronous process, this error
		// does not kill the parent process.
		throw(
			type = "threadError",
			message = "Something went wrong in the thread!"
		);

	}


	// ------------------------------------------------------ //
	// ------------------------------------------------------ //


	// Wait for all threads to finish and the run the given
	// callback.
	//
	// NOTE: For demo purposes, we're going to JOIN the threads so
	// that we can write to the page output.
	threadsDone(
		cfthread.thread1,
		cfthread.thread2,
		cfthread.thread3,
		function( thread1, thread2, thread3 ){

			// Log the status of the completed threads.
			console.log( "Threads have finished! #now()#<br />" );
			console.log( "#thread1.name# - #thread1.status#<br />" );
			console.log( "#thread2.name# - #thread2.status#<br />" );
			console.log( "#thread3.name# - #thread3.status#<br />" );

		}
	);


	// ------------------------------------------------------ //
	// ------------------------------------------------------ //


	// Wait for all threads to join so we can see the output.
	thread action="join";

	// Debug threads.
	// writeDump( cfthread );


</cfscript>