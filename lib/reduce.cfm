<cfscript>
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
</cfscript>