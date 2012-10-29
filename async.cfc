component name="async" extends="foundry.core" {
	public any function init() {
		variables._ = require("util",this);
		variables.console = require("console");

		// this.map = doParallel('_map');
		// this.mapSeries = doSeries('_map');
	    // // inject alias
	    // this.inject = this.reduce;
	    // // foldl alias
	    // this.foldl = this.reduce;
	    // // foldr alias
	    // this.foldr = this.reduceRight;
	    
        this.filter = doParallel('_filter');
	   // this.filterSeries = doSeries('_filter');

	    // // select alias
	    // this.select = this.filter;
	    // this.selectSeries = this.filterSeries;
	    // this.reject = doParallel('_reject');
	    // this.rejectSeries = doSeries('_reject');

	    // this.detect = doParallel('_detect');
	    // this.detectSeries = doSeries('_detect');
	    // // any alias
	    // this.any = this.some;
	    // // all alias
	    // this.all = this.every;
	    // this.concat = doParallel('_concat');
	    // this.concatSeries = doSeries('_concat');
	    // this.log = _console_fn('log');
	    // this.dir = _console_fn('dir');
	    // /*this.info = _console_fn('info');
	    // this.warn = _console_fn('warn');
	    // this.error = _console_fn('error');*/

		return this;
	}

    include "lib/each.cfm";

 	private any function doParallel(fn) {
        fnc = arguments.fn;
        var args = {};
    	
        returnFn = function() {
            var fn2 = this[fnc];
            args['eachfn'] = this.forEach;
            args['arr'] = arguments['1'];
            args['iterator'] = arguments['2'];
            args['callback'] = arguments['3'];
            for(key in structKeyArray(arguments)) {
                args[key] = arguments[key];
            }

            return fn2(argumentCollection=args);
        };
        return returnFn;
    };

    private any function doSeries(fn) {
        returnFn = function() {
    		structPrepend(arguments,{'0':this.forEachSeries});
            return _[fn](argumentCollection=arguments);
        };
        return returnFn;
    };

	include "lib/map.cfm";

	include "lib/reduce.cfm";

    include "lib/filter.cfm";

    include "lib/reject.cfm";
    
    include "lib/detect.cfm";

    include "lib/some.cfm";

    include "lib/every.cfm";

    include "lib/sortBy.cfm";

    include "lib/auto.cfm";

    include "lib/waterfall.cfm";

 	public any function parallel(tasks, callback) {
        callback = _.isFunction(callback)? callback : noop;
        
        if (_.isArray(tasks.constructor)) {
            this.map(tasks, function (fn, callback) {
                if (fn) {
                    fn(function (err) {
                        var args = Array.prototype.slice.call(arguments, 1);
                        if (args.length <= 1) {
                            args = args[0];
                        }
                        callback.call(returnNull(), err, args);
                    });
                }
            }, callback);
        } else {
            var results = {};
            this.forEach(_keys(tasks), function (k, callback) {
                tasks[k](function (err) {
                    var args = require("arrayObj",arguments).slice();
                    if (args.length <= 1) {
                        args = args[0];
                    }
                    results[k] = args;
                    callback(err);
                });
            }, function (err) {
                callback(err, results);
            });
        }
    };


    public any function series(tasks, callback) {
        callback = callback || function () {};
        if (tasks.constructor === Array) {
            this.mapSeries(tasks, function (fn, callback) {
                if (fn) {
                    fn(function (err) {
                        var args = Array.prototype.slice.call(arguments, 1);
                        if (args.length <= 1) {
                            args = args[0];
                        }
                        callback.call(null, err, args);
                    });
                }
            }, callback);
        }
        else {
            var results = {};
            this.forEachSeries(_keys(tasks), function (k, callback) {
                tasks[k](function (err) {
                    var args = Array.prototype.slice.call(arguments, 1);
                    if (args.length <= 1) {
                        args = args[0];
                    }
                    results[k] = args;
                    callback(err);
                });
            }, function (err) {
                callback(err, results);
            });
        }
    };

    public any function iterator(tasks) {
        var makeCallback = function (index) {
            var fn = function () {
                if (tasks.length) {
                    tasks[index].apply(null, arguments);
                }
                return fn.next();
            };
            fn.next = function () {
                return (index < tasks.length - 1) ? makeCallback(index + 1): null;
            };
            return fn;
        };
        return makeCallback(0);
    };

    public any function apply(fn) {
        var args = Array.prototype.slice.call(arguments, 1);
        return function () {
            return fn.apply(
                null, args.concat(Array.prototype.slice.call(arguments))
            );
        };
    };

    private any function _concat(eachfn, arr, fn, callback) {
        var r = [];
        eachfn(arr, function (x, cb) {
            fn(x, function (err, y) {
                r = r.concat(y || []);
                cb(err);
            });
        }, function (err) {
            callback(err, r);
        });
    };

    public any function whilst(test, iterator, callback) {
        if (test()) {
            iterator(function (err) {
                if (err) {
                    return callback(err);
                }
                this.whilst(test, iterator, callback);
            });
        }
        else {
            callback();
        }
    };

    public any function until(test, iterator, callback) {
        if (!test()) {
            iterator(function (err) {
                if (err) {
                    return callback(err);
                }
                this.until(test, iterator, callback);
            });
        }
        else {
            callback();
        }
    };

    public any function queue(worker, concurrency) {
        var workers = 0;
        var q = {
            tasks: [],
            concurrency: concurrency,
            saturated: null,
            empty: null,
            drain: null,
            push: function (data, callback) {
                if(data.constructor !== Array) {
                    data = [data];
                }
                _forEach(data, function(task) {
                    q.tasks.push({
                        data: task,
                        callback: _.isFunction(callback) ? callback : returnNull()
                    });
                    if (q.saturated AND q.tasks.length EQ concurrency) {
                        q.saturated();
                    }
                    this.nextTick(q.process);
                });
            },
            process: function () {
                if (workers < q.concurrency && q.tasks.length) {
                    var task = q.tasks.shift();
                    if(q.empty && q.tasks.length == 0) q.empty();
                    workers += 1;
                    worker(task.data, function () {
                        workers -= 1;
                        if (task.callback) {
                            task.callback.apply(task, arguments);
                        }
                        if(q.drain && q.tasks.length + workers == 0) q.drain();
                        q.process();
                    });
                }
            },
            length: function () {
                return q.tasks.length;
            },
            running: function () {
                return workers;
            }
        };
        return q;
    };

    private any function _console_fn(name) {
        return function (fn) {
            var args = Array.prototype.slice.call(arguments, 1);
            fn.apply(null, args.concat([function (err) {
                var args = Array.prototype.slice.call(arguments, 1);
                if (isDefined("console")) {
                    if (err) {
                        if (console.error) {
                            console.error(err);
                        }
                    }
                    else if (console[name]) {
                        _forEach(args, function (x) {
                            console[name](x);
                        });
                    }
                }
            }]));
        };
    };


    public any function memoize(fn, hasher) {
        var memo = {};
        var queues = {};
        hasher = hasher || function (x) {
            return x;
        };
        var memoized = function () {
            var args = Array.prototype.slice.call(arguments);
            var callback = args.pop();
            var key = hasher.apply(null, args);
            if (structKeyExists(memo,key)) {
                callback.apply(null, memo[key]);
            } else if (structKeyExists(queues,key)) {
                queues[key].push(callback);
            } else {
                queues[key] = [callback];
                fn.apply(null, args.concat([function () {
                    memo[key] = arguments;
                    var q = queues[key];
                    structDelete(queues,key);
                    l = structCount(q);
                    for (var i = 0; i < l; i++) {
                      var func = q[i];
                      func(argumentCollection=arguments);
                    }
                }]));
            }
        };
        memoized.unmemoized = fn;
        return memoized;
    };

    public any function unmemoize(fn) {
      return function () {
        return (fn.unmemoized || fn).apply(null, arguments);
      };
    };



    // public any function onMissingMethod(name,args) {
    // 	var fn = evaluate("_.#name#");
    // 	if(name DOES NOT CONTAIN "series") {
    // 		return this.doParallel(fn);
    // 	} else {
    // 		return this.doSeries(fn);
    // 	}
    // }


    private void function returnNull() {

    }

    /**
	* arrayCollection UDF
	*  @Author Ben Nadel <http://bennadel.com/>
	*/
	private struct function arrayCollection(array arr) {
		var local = {};
		local.keys = createObject( "java", "java.util.LinkedHashMap" ).init();

		for(var i=1; i <= arrayLen(arguments.arr); i++) {
			if (arrayIsDefined( arguments.arr, i)) {
				local.keys.put(javaCast( "string", i),arguments.arr[i]);
			};
		};
	 
		return local.keys;
	}

    /**
     * This function allows you to share the underlying ExecutorService with multiple concurrent methods.<br/>
     * For example, this shares a threadpool of 10 threads across multiple _eachParrallel calls:<br/>
     * _withPool( 10, function() {<br/>
     * _eachParrallel(array, function() { ... });<br/>
     * _eachParrallel(array, function() { ... });<br/>
     * _eachParrallel(array, function() { ... });<br/>
     * });
     *
     * @limit the number of threads to use in the thread pool for processing.
     * @closure the closure that contains the calls to other concurrent library functions.
     */
    public void function _withPool(required numeric limit, required function closure)
    {
        request["sesame-concurrency-es"] = createObject("java", "java.util.concurrent.Executors").newFixedThreadPool(arguments.limit);

        try
        {
            arguments.closure();
        }
        catch(Any exc)
        {
            rethrow;
        }
        finally
        {
            request["sesame-concurrency-es"].shutdown();
            StructDelete(request, "sesame-concurrency-es");
        }
    }
    
    /**
     * Run the closure in a thread. Must be run inside a _withPool() block to set up the ExecutorService, and close it off at the end.
     * For example:<br/>
     * _withPool( 10, function() {<br/>
     * _thread(function() { ... });<br/>
     * _thread(function() { ... });<br/>
     * });
     *<br/>
     * Return an instance of java.util.concurrent.Future to give you control over the closure, and/or retrieve the value returned from the closure.
     *
     * @closure the closure to call asynchronously
     */
    public any function _thread(required function closure)
    {
        var executorService = request["sesame-concurrency-es"];
        var callable = new lib.ClosureConcurrent(arguments.closure);

        return executorService.submit(callable.toCallable());
    }
/*
	* 	@hint Internal helper function. Converts boolean equivalents to boolean true or false. Helpful for keeping function return values consistent.
	*/
	private boolean function toBoolean(required obj) {
		return !!arguments.obj;
	}
    private any function noop() {}
}