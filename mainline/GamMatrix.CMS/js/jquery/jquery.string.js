String.prototype.htmlEncode = function (ignoreServerCode) {
    var $str = this;

    if (ignoreServerCode != true) {
        var $regex = new RegExp("([^\\x00-\\x7F]|&|\\\"|\\<|\\>|')", "g");
        return $str.replace($regex, function ($1) {
            return "&#" + $1.charCodeAt(0).toString(10) + ";";
        });
    }
    else {
        var $regex = new RegExp("((\\<\\%(.*?)%\\>)|[^\\x00-\\x7F]|&|\\\"|\\<|\\>|')", "g");
        return $str.replace($regex, function ($1) {
            if ($1 != null) {
                if ($1.length == 1)
                    return "&#" + $1.charCodeAt(0).toString(10) + ";";
                else if ($1.length > 1)
                    return $1;
            }
            return "";
        });
    }
};

String.prototype.htmlDecode = function () {
    var $str = this;
    return $str;
};


String.prototype.scriptEncode = function () {
    var $str = this;
    var $regex = new RegExp("([^\\x00-\\x7F]|&|\\\"|'|\\<|\\>|\\n|\\r|\\t)", "g");
    return $str.replace($regex, function ($1) {
        var $ret = $1.charCodeAt(0).toString(16);
        while ($ret.length < 4) $ret = "0" + $ret;
        return "\\u" + $ret;
    });
};

String.prototype.padLeft = function ($padChar, $length) {
    var $str = this;
    if($str == null) $str = "";
    while ($str.length < $length) $str = $padChar + $str;
    return $str;
};

String.prototype.padRight = function ($padChar, $length) {
    var $str = this;
    if ($str == null) $str = "";
    while ($str.length < $length) $str = $str + $padChar;
    return $str;
};

String.prototype.trim = function () {
    return this.replace(/^\s+|\s+$/g, "");
}

String.prototype.trimLeft = function () {
    return this.replace(/^\s+/, "");
}

String.prototype.trimRight = function () {
    return this.replace(/\s+$/, "");
}


$.extend({
    htmlEncode: function ($str) {
        if ($str == null) return "";
        return $str.toString().htmlEncode();
    },

    scriptEncode: function ($str) {
        if ($str == null) return "";
        return $str.toString().scriptEncode();
    },

    padLeft: function ($str, $padChar, $length) {
        if ($str == null) $str = "";
        return $str.toString().padLeft($padChar, $length);
    },

    padRight: function ($str, $padChar, $length) {
        if ($str == null) $str = "";
        return $str.toString().padRight($padChar, $length);
    },

    trim: function ($str) {
        if ($str == null) $str = "";
        return $str.toString().trim();
    },

    trimLeft: function ($str) {
        if ($str == null) $str = "";
        return $str.toString().trimLeft();
    },

    trimRight: function ($str) {
        if ($str == null) $str = "";
        return $str.toString().trimRight();
    }
});