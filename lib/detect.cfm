<cfscript>
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
</cfscript>