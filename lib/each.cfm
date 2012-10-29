<cfscript>
//ASYNC forEach()
/**
 * Do each iteration in it's own thread, and then join it all back again at the end.
 *
 * @data the array/struct to perform a closure on
 * @closure the closure to pass through the elements from data to.
 * @limit number of threads to use in the thread pool for processing. (Only needed if you aren't using _withPool())
 */
public void function forEach(required any data, required function iterator, cb, numeric limit=5)
{
    var futures = [];
    var _closure = arguments.iterator;

    if(!structKeyExists(request, "sesame-concurrency-es"))
    {
        var executorService = createObject("java", "java.util.concurrent.Executors").newFixedThreadPool(arguments.limit);
        var shutDownEs = true;
    }
    else
    {
        var executorService = request["sesame-concurrency-es"];
        var shutDownEs = false;
    }

    try
    {
        if(isArray(arguments.data))
        {
            for(var item in arguments.data)
            {
                var args ={1=item};
                var runnable = new lib.ClosureConcurrent(_closure, args);

                runnable = createDynamicProxy(runnable, ["java.lang.Runnable"]);

                var future = executorService.submit(runnable);

                arrayAppend(futures, future);
            }
        }

        if(isStruct(arguments.data))
        {
            for(var key in arguments.data)
            {
                var args ={1=key, 2=arguments.data[key]};
                var runnable = new lib.ClosureConcurrent(_closure, args);

                var future = executorService.submit(runnable.toRunnable());

                arrayAppend(futures, future);
            }
        }

        //join it all back up
        ArrayEach(futures, function(it) { it.get(); });
    }
    catch(Any exc)
    {
        rethrow;
    }
    finally
    {
        if(shutDownEs)
        {
            executorService.shutdown();
            cb(returnNull());
        }
    }
}

public any function forEachSeries(arr, iterator, cb) {
    var callback = _.isFunction(cb)? cb : noop;
    
    if (arrayLen(arr) EQ 0) {
        return callback();
    }

    var completed = 0;
	var iterate = function () {
		//THREAD START
		iterator(arr[completed+1], function (err) {
				if (structKeyExists(arguments,'err')) {
	            	console.log("error: " & err.message);
	                
	                callback(err);
	                callback = noop;
	            } else {
	                completed++;
	            	console.log("completed: " & completed);
	                if (completed EQ arrayLen(arr)) {
	                    callback(returnNull());
	                } else {
	                    iterate();
	                }
	            }

	        });
	};

	iterate();
};

public any function forEachLimit(arr, limit, iterator, cb) {
    var callback = _.isFunction(cb)? cb : noop;
    
    if (arrayLen(arr) EQ 0 OR limit LTE 0) {
        return callback();
    }

    var completed = 0;
    var started = 0;
    var running = 0;

   var replenish = function() {
        if (completed EQ arrayLen(arr)) {
            callback();
        }

        while (running < limit AND started < arrayLen(arr)) {
            started++;
            running++;
            iterator(arr[started], function (err) {
                if (structKeyExists(arguments,'err')) {
                	console.log("error: " & err.message);
                    callback(err);
                    callback = noop;
                } else {
                    completed++;
                    running++;
                    console.log("completed: " & completed);
                    if (completed EQ arrayLen(arr)) {
                        callback();
                    }
                    else {
                        replenish();
                    }
                }
            });
        }
    };

    replenish();
};
</cfscript>