<cfscript>
private any function _filter(eachfn, arr, iterator, callback) {
        var results = [];
        
        var arrMap = _.map(arr, function (x, i) {
            return {index: i, value: x};
        });
        eachfn = arguments.eachfn;
        eachfn(arrMap, function (x, callback) {
            iterator(x.value, function (v) {
                if (!_.isEmpty(v)) {
                    results.push(x);
                }
                callback();
            });
        }, function (err) {
            callback(_.map(_.sort(results,function (a, b) {
                return a.index - b.index;
            }), function (x) {
                writeDump(var=arguments,abort=true);
                return x.value;
            }));
        });
    };
</cfscript>