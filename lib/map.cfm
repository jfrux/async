<cfscript>
private any function _map(eachfn, arr, iterator, callback) {
	    var results = [];
	    arrMap = _.map(arr, function (x, i) {
	        return {index: i, value: x};
	    });

	    eachfn(arrMap, function (x, callback) {
	        iterator(x.value, function (err, v) {
	            results[x.index] = v;
	            callback(err);
	        });
	    }, function (err) {
	        callback(err, results);
	    });
	};
	</cfscript>