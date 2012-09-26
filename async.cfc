component name="async" extends="foundry.core" {
	
	//borrowed from UnderscoreCF
	variables._forEach(obj = this.obj, iterator = _.identity, this = {}) {
		if (isArray(arguments.obj)) {
			var index = 1;
			for (element in arguments.obj) {
				if (arrayIsDefined(arguments.obj, index)) {
					iterator(element, index, arguments.obj, arguments.this);
				}
				index++;
			}
		}
		else if (isObject(arguments.obj) || isStruct(arguments.obj)) {
			for (key in arguments.obj) {
				var val = arguments.obj[key];
				iterator(val, key, arguments.obj, arguments.this);
			}
		}
		else {
			// query or something else? convert to array and recurse
			_.each(toArray(arguments.obj), iterator, arguments.this);
		}
 	}

 	//ASYNC forEach()
	public any function forEach = function (arr, iterator, callback) {
        callback = callback || function () {};
        
        if (!arrayLen(arr)) {
            return callback();
        }

        var completed = 0;

        _forEach(arr, function (x) {
            iterator(x, function (err) {
                if (err) {
                    callback(err);
                    callback = function () {};
                }
                else {
                    completed += 1;
                    if (completed EQ arrayLen(arr)) {
                        callback(null);
                    }
                }
            });
        });
    };
}