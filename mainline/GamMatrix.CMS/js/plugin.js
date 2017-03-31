// String format : 'str1-{0} str2-{1}'.format('str1', 'str2')
String.prototype.format = function () {
    if (arguments.length == 0)
        return this;

    var str = this;
    for (var i = 0; i < arguments.length; i++) {
        var re = new RegExp('\\{' + (i) + '\\}', 'gm');
        str = str.replace(re, arguments[i]);
    }
    return str;
}

// String replicator 
String.prototype.times = function (n) {
    var s = '';
    for (var i = 0; i < n; i++)
        s += this;

    return s;
}

// Zero-Padding
// String
String.prototype.zp = function (n) { return '0'.times(n - this.length) + this; }
// Number
Number.prototype.zp = function (n) { return this.toString().zp(n); }

