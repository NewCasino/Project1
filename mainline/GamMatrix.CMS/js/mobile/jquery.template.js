$.fn.parseTemplate = function (data) {
	var str = (this).html();
	var _tmplCache = {}
	var err = "";
	try {
		var func = _tmplCache[str];
		if (!func) {
			var strFunc =
			"var p=[],print=function(){p.push.apply(p,arguments);};" +
						"with(obj){p.push('" +
			str.replace(/[\r\t\n]/g, " ")
			   .replace(/'(?=[^#]*#>)/g, "\t")
			   .split("'").join("\\'")
			   .split("\t").join("'")
			   .replace(/<#=(.+?)#>/g, "',$1,'")
			   .split("<#").join("');")
			   .split("#>").join("p.push('")
			   + "');}return p.join('');";

			//alert(strFunc);
			func = new Function("obj", strFunc);
			_tmplCache[str] = func;
		}
		return func(data);
	} catch (e) { err = e.message; }
	return "< # ERROR: " + err.toString() + " # >";
}

String.prototype.htmlEncode = function () {
	var $str = this;

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
};