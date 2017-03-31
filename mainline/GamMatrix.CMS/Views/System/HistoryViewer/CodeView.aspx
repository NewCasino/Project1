<%@ Page Language="C#" AutoEventWireup="true" Inherits="CM.Web.ViewPageEx" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title><%=(this.ViewData["Title"] as string).SafeHtmlEncode() %></title>
    <script language="javascript" type="text/javascript" src="/js/swfobject.js"></script>
    <style type="text/css">
        html, body { overflow:hidden; width:100%; height:100%; padding:0px; margin:0px; }
    </style>
</head>
<body>
<div id="place-holder"></div>


<script language="javascript" type="text/javascript">
function onEditorLoaded() {
    try {
        document.getElementById('ctlFlash').setText('<%=(this.ViewData["FileContent"] as string).SafeJavascriptStringEncode() %>');
    } catch (e) { /*alert(e)*/ }
}
// initialize with parameters
var flashvars = {
    parser: "aspx",
    readOnly: true,
    preferredFonts: "|Fixedsys|Fixedsys Excelsior 3.01|Fixedsys Excelsior 3.00|Courier New|Courier|",
    onload: "onEditorLoaded"
};

var params = { menu: "false", wmode: "wmode", allowscriptaccess: "always" };
var attributes = { id: "ctlFlash", name: "ctlFlash" };

swfobject.embedSWF("/js/CodeHighlightEditor.swf", "place-holder", "100%", "100%", "10.0.0", "/js/expressInstall.swf", flashvars, params, attributes);
</script>

</body>
</html>
