<cfscript>
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
</cfscript>