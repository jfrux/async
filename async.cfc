component name="async" extends="foundry.core" {
	public any function init() {
		variables._ = require("util",this);
		variables.console = require("console");
		// this.this.map = doParallel(_asyncMap);
		// this.this.mapSeries = doSeries(_asyncMap);
		

		this.map = doParallel(_asyncMap);
		this.mapSeries = doSeries(_asyncMap);
	    // inject alias
	    this.inject = this.reduce;
	    // foldl alias
	    this.foldl = this.reduce;
	    // foldr alias
	    this.foldr = this.reduceRight;
	    this.filter = doParallel(_filter);
	    this.filterSeries = doSeries(_filter);
	    // select alias
	    this.select = this.filter;
	    this.selectSeries = this.filterSeries;
	    this.reject = doParallel(_reject);
	    this.rejectSeries = doSeries(_reject);

	    this.detect = doParallel(_detect);
	    this.detectSeries = doSeries(_detect);
	    // any alias
	    this.any = this.some;
	    // all alias
	    this.all = this.every;
	    this.concat = doParallel(_concat);
	    this.concatSeries = doSeries(_concat);
	    this.log = _console_fn('log');
	    this.dir = _console_fn('dir');
	    /*this.info = _console_fn('info');
	    this.warn = _console_fn('warn');
	    this.error = _console_fn('error');*/

		return this;
	}

 	//ASYNC forEach()
	public any function forEach(arr, iterator, cb) {
        var callback = _.isFunction(cb)? cb : noop;
        
        if (arrayLen(arr) EQ 0) {
            return callback();
        }

        var completed = 0;
        
        _.forEach(arr, function (x) {
            testThread = getPageContext().getThread();
            writeDump(var=testThread.getName());
            
        	iterator(x, function (err) {
                if (structKeyExists(arguments,'err')) {
                	console.log("error: " & err.message);
                    callback(err);
                    callback = noop;
                } else {
                    completed++;
                    console.log("completed: " & completed);
                    if (completed EQ arrayLen(arr)) {
                        callback(returnNull());
                    }
                }
            });
        });
   	};

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


    private any function doParallel(fn) {
    	returnFn = function() {
    		structPrepend(arguments,{'0':this.forEach});
            return _[fn](argumentCollection=arguments);
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

	private any function _asyncMap(eachfn, arr, iterator, callback) {
	    var results = [];
	    arr = _.map(arr, function (x, i) {
	        return {index: i, value: x};
	    });

	    eachfn(arr, function (x, callback) {
	        iterator(x.value, function (err, v) {
	            results[x.index] = v;
	            callback(err);
	        });
	    }, function (err) {
	        callback(err, results);
	    });
	};

	public any function reduce(arr, memo, iterator, callback) {
        this.forEachSeries(arr, function (x, callback) {
            iterator(memo, x, function (err, v) {
                memo = v;
                callback(err);
            });
        }, function (err) {
            callback(err, memo);
        });
    };
    

    public any function reduceRight(arr, memo, iterator, callback) {
        var reversed = _map(arr, function (x) {
            return x;
        }).reverse();
        this.reduce(reversed, memo, iterator, callback);
    };

    private any function _filter(eachfn, arr, iterator, callback) {
        var results = [];
        arr = _map(arr, function (x, i) {
            return {index: i, value: x};
        });
        eachfn(arr, function (x, callback) {
            iterator(x.value, function (v) {
                if (v) {
                    results.push(x);
                }
                callback();
            });
        }, function (err) {
            callback(_map(results.sort(function (a, b) {
                return a.index - b.index;
            }), function (x) {
                return x.value;
            }));
        });
    };


    private any function _reject(eachfn, arr, iterator, callback) {
        var results = [];
        arr = _map(arr, function (x, i) {
            return {index: i, value: x};
        });
        eachfn(arr, function (x, callback) {
            iterator(x.value, function (v) {
                if (!v) {
                    results.push(x);
                }
                callback();
            });
        }, function (err) {
            callback(_map(results.sort(function (a, b) {
                return a.index - b.index;
            }), function (x) {
                return x.value;
            }));
        });
    };

    private any function _detect(eachfn, arr, iterator, main_callback) {
        eachfn(arr, function (x, callback) {
            iterator(x, function (result) {
                if (result) {
                    main_callback(x);
                    main_callback = function () {};
                }
                else {
                    callback();
                }
            });
        }, function (err) {
            main_callback();
        });
    };

    public any function some(arr, iterator, main_callback) {
        this.forEach(arr, function (x, callback) {
            iterator(x, function (v) {
                if (v) {
                    main_callback(true);
                    main_callback = function () {};
                }
                callback();
            });
        }, function (err) {
            main_callback(false);
        });
    };


    public any function every(arr, iterator, main_callback) {
        this.forEach(arr, function (x, callback) {
            iterator(x, function (v) {
                if (!v) {
                    main_callback(false);
                    main_callback = function () {};
                }
                callback();
            });
        }, function (err) {
            main_callback(true);
        });
    };

    

    private any function sortBy(arr, iterator, callback) {
        this.map(arr, function (x, callback) {
            iterator(x, function (err, criteria) {
                if (err) {
                    callback(err);
                }
                else {
                    callback(null, {value: x, criteria: criteria});
                }
            });
        }, function (err, results) {
            if (err) {
                return callback(err);
            }
            else {
                var fn = function (left, right) {
                    var a = left.criteria;
                    var b = right.criteria;
                    return a < b ? -1 : a > b ? 1 : 0;
                };
                callback(null, _map(results.sort(fn), function (x) {
                    return x.value;
                }));
            }
        });
    };

    public any function auto(tasks, callback) {
        callback = callback || function () {};
        var keys = _keys(tasks);
        if (!keys.length) {
            return callback(null);
        }

        var results = {};

        var listeners = [];
        var addListener = function (fn) {
            listeners.unshift(fn);
        };
        var removeListener = function (fn) {
            for (var i = 0; i < listeners.length; i += 1) {
                if (listeners[i] === fn) {
                    listeners.splice(i, 1);
                    return;
                }
            }
        };
        var taskComplete = function () {
            _forEach(listeners.slice(0), function (fn) {
                fn();
            });
        };

        addListener(function () {
            if (_keys(results).length === keys.length) {
                callback(null, results);
                callback = function () {};
            }
        });

        _forEach(keys, function (k) {
            var task = (_.isFunction(tasks[k])) ? [tasks[k]]: tasks[k];
            var taskCallback = function (err) {
                if (err) {
                    callback(err);
                    // stop subsequent errors hitting callback multiple times
                    callback = function () {};
                }
                else {
                    var args = Array.prototype.slice.call(arguments, 1);
                    if (args.length <= 1) {
                        args = args[0];
                    }
                    results[k] = args;
                    taskComplete();
                }
            };
            var requires = task.slice(0, Math.abs(task.length - 1)) || [];
            var ready = function () {
                return _reduce(requires, function (a, x) {
                    return (a && results.hasOwnProperty(x));
                }, true) && !results.hasOwnProperty(k);
            };
            if (ready()) {
                task[task.length - 1](taskCallback, results);
            }
            else {
                var listener = function () {
                    if (ready()) {
                        removeListener(listener);
                        task[task.length - 1](taskCallback, results);
                    }
                };
                addListener(listener);
            }
        });
    };

    public any function waterfall(tasks, callback) {
        // callback = callback || function () {};
        // if (!tasks.length) {
        //     return callback();
        // }
        // var wrapIterator = function (iterator) {
        //     return function (err) {
        //         if (err) {
        //             callback(err);
        //             callback = function () {};
        //         }
        //         else {
        //             var args = Array.prototype.slice.call(arguments, 1);
        //             var next = iterator.next();
        //             if (next) {
        //                 args.push(wrapIterator(next));
        //             }
        //             else {
        //                 args.push(callback);
        //             }
        //             this.nextTick(function () {
        //                 iterator.apply(null, args);
        //             });
        //         }
        //     };
        // };

        // wrapIterator(this.iterator(tasks))();
    };
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
	
	// I accept N thread instances and a callback (the last
	// argument). The callback is invoked when each one of the given
	// threads has completed execution (success or failure). The
	// thread object is echoed back in the callback arguments.
	function threadsDone(){
		// Extract the callback from the arguemnts.
		var callback = arguments[ arrayLen( arguments ) ];

		// Extract the thread objects - arguments[1..N-1].
		var threads = arraySlice( arguments, 1, arrayLen( arguments ) - 1 );

		// I am a utiltiy function that determine if a given thread
		// is still running based on its status.
		var isThreadRunning = function( threadInstance ){

			console.log("threadStatus: " & threadInstance.status);
			// A thread can end with a success or an error, both of
			// which lead to different final status values.
			return(
				(threadInstance.status != "TERMINATED") &&
				(threadInstance.status != "COMPLETED")
			);

		};

		// I am a utility function that determines if any of the
		// given blogs are still running.
		var threadsAreRunning = function(){
			// Loop over each thread to look for at least ONE that is
			// still running.
			for (var threadInstance in threads){
				console.log("threadStatus: " & threadInstance.status);
			
				// Check to see if this thread is still running. This
				// is if it has not yet completed (successfully) or
				// terminated (error).
				if (isThreadRunning( threadInstance )){

					// We don't need to continue searching; if this
					// thread is running, that's good enough.
					return( true );

				}

			}

			// If we made it this far, then no threads are running.
			return( false );

		};

		// I am utility function that invokes the callback with the
		// given thread instances.
		var invokeCallback = function(){
			// All of the threads we are monitoring have stopped
			// running. Now, we can invoke the callback. Let's build
			// up an argument collection.
			var callbackArguments = {};

			// Translate the array-based arguments into a struct-
			// based collection of arguments.
			for (var i = 1 ; i < arrayLen( threads ) ; i++){

				callbackArguments[ i ] = threads[ i ];

			}

			// Invoke the callback with the given threads.
			callback( argumentCollection = callbackArguments );

		};

		// In order to check the threads, we need to launch an
		// additional thread to act as a monitor. This will do
		// nothing but sleep and check the threads.
		//
		// NOTE: We need to pass the two methods INTO the thread
		// explicitly since the thread body does NOT have access
		// to the local scope of the parent function.
		thread
			name = "threadsDone_#getTickCount()#"
			action = "run"
			threadsarerunning = threadsAreRunning
			invokecallback = invokeCallback
			{

			// Check to see if the threads are running.
			while (threadsAreRunning()){

				// Sleep briefly to allow other threads to complete.
				thread
					action="sleep"
					duration="10"
				;

			}

			// If we made it this far, it means that the threads
			// have all finished executing and the while-loop has
			// been exited. Let's invoke the callback.
			invokeCallback();

		};

	}
/*
	* 	@hint Internal helper function. Converts boolean equivalents to boolean true or false. Helpful for keeping function return values consistent.
	*/
	private boolean function toBoolean(required obj) {
		return !!arguments.obj;
	}
    private any function noop() {}
}