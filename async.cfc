component name="async" extends="foundry.core" {
	public any function init() {
		variables._ = require("util",this);
		variables.console = require("console");
		// this.async.map = doParallel(_asyncMap);
		// this.async.mapSeries = doSeries(_asyncMap);
		for(func in getMetaData(_).functions) {
			if(func.name NEQ "init" AND func.name NEQ "toBoolean") {
				this['#func.name#'] = doParallel(_["#func.name#"]);
				this['#func.name#Series'] = doSeries(_["#func.name#"]);
			}
		}

		return this;
	}

 	public any function parallel(tasks, callback) {
        callback = _.isFunction(callback)? callback : noop;
        
        if (_.isArray(tasks.constructor)) {
            async.map(tasks, function (fn, callback) {
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
        }
        else {
            var results = {};
            async.forEach(_keys(tasks), function (k, callback) {
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

	public any function _asyncMap(eachfn, arr, iterator, callback) {
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

	
 	//ASYNC forEach()
	public any function forEach(arr, iterator, cb) {
        var callback = _.isFunction(cb)? cb : noop;
        
        if (arrayLen(arr) EQ 0) {
            return callback();
        }

        var completed = 0;

        _.forEach(arr, function (x) {
        	console.log("x: " & x);
            iterator(x, function (err) {
                if (structKeyExists(arguments,'err')) {
                	console.log("completed: " & completed);
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

    // public any function onMissingMethod(name,args) {
    // 	var fn = evaluate("_.#name#");
    // 	if(name DOES NOT CONTAIN "series") {
    // 		return this.doParallel(fn);
    // 	} else {
    // 		return this.doSeries(fn);
    // 	}
    // }

    private any function doParallel(fn) {
    	returnFn = function() {
            return _[fn](argumentCollection=arguments);
        };
        return returnFn;
    };

    private any function doSeries(fn) {
        returnFn = function() {
            return _[fn](argumentCollection=arguments);
        };
        return returnFn;
    };

    private void function returnNull() {

    }

    /**
	* arrayCollection UDF
	*  @Author Ben Nadel <http://bennadel.com/>
	*/
	public struct function arrayCollection(array arr) {
		var local = {};
		local.keys = createObject( "java", "java.util.LinkedHashMap" ).init();

		for(var i=1; i <= arrayLen(arguments.arr); i++) {
			if (arrayIsDefined( arguments.arr, i)) {
				local.keys.put(javaCast( "string", i),arguments.arr[i]);
			};
		};
	 
		return local.keys;
	}
/*
	* 	@hint Internal helper function. Converts boolean equivalents to boolean true or false. Helpful for keeping function return values consistent.
	*/
	private boolean function toBoolean(required obj) {
		return !!arguments.obj;
	}
    public any function noop() {}
}