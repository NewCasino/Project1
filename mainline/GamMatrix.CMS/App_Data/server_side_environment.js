String.prototype.htmlEncode = function () {
    return _htmlEncode(this);
};

String.prototype.scriptEncode = function () {
    return _scriptEncode(this);
};

function _parseTemplate(str, data) {
    if (data == null)
        data = [];
    var err = "";
    try {
        var strFunc =
        "var p=[],print=function(){p.push.apply(p,arguments);};" +
                    "with(obj){p.push('" +
        str.replace(/[\r\t\n]/g, " ")
            .replace(/''(?![^#]*>|[^#]*#>|[^<]*#)/g, "\\'")
            .replace(/<#=(.+?)#>/g, "',$1,'")
            .split("<#").join("');")
            .split("#>").join("p.push('")
            + "');}return p.join('');";

        var func = new Function("obj", strFunc);
        return func(data);
    } catch (e) { err = e.message; }
    return "< # ERROR: " + err.toString() + " # >";
}