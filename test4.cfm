<!---
	Start a CFScript block. Closures can only be used inside
	of CFScript due to the syntax required to define them.
--->
<cfscript>


	// Run a thread that composes a function and a closure.
	thread
		name = "testComposition"
		action = "run"
		{

		// Cannot use a FUNCTION DECLARATION inside of a CFThread
		// since CFThread runs as a Function behind the scenes and
		// function declarations cannot be nested.
		//
		// Error: Invalid CFML construct found on line X at column Y.
		// The function innerFunction is incorrectly nested inside
		// another function definition
		// _cffunccfthread_cfthread42ecfm2828400851.

		function innerFunction(){ };

		// Define an inner closure. We *know* this will work.
		var innerClosure = function(){ };


		// Define an inner closure that, itself, defines a Function.
		var innerComposite = function(){

			function innerInnerFunction(){ }

			innerInnerFunction();

		};

		// Try invoking composite closure.
		innerComposite();

	}


	// ------------------------------------------------------ //
	// ------------------------------------------------------ //


	// Join thread back to page so we can debug the output.
	thread action = "join";

	// Debug the thread.
	writeDump( cfthread );


</cfscript>