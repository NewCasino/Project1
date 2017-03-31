<%@ Page Title="<%$ Metadata:value(.Title) %>" Language="C#" Inherits="CM.Web.ViewPageEx<dynamic>"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/combined.js") %>"></script>
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/inputfield.js") %>"></script>
    <style type="text/css">
        html, body { overflow:hidden; background-color:White; width:100%; height:100%; }
    </style>
</head>


<body>

<table cellpadding="0" cellspacing="0" border="0" style="width:100%; height:100%; table-layout:fixed;">
    <tr>
        <td style="width:20%" valign="top" align="left">
            <h3>Standard HTML Components</h3>
            <hr />
            <ul>
                <li>
                <a target="ifmMain" href="<%: this.Url.RouteUrl("Tutorial", new { @action = "ShowView", @viewName="Sample_Header"}) %>">Headers(H1/H2/...)</a>
                </li>
                <li>
                <a target="ifmMain" href="<%: this.Url.RouteUrl("Tutorial", new { @action = "ShowView", @viewName="Sample_Fieldset"}) %>">Fieldset</a>
                </li>
                <li>
                <a target="ifmMain" href="<%: this.Url.RouteUrl("Tutorial", new { @action = "ShowView", @viewName="Sample_Panel"}) %>">Panel</a>
                </li>
                <li>
                <a target="ifmMain" href="<%: this.Url.RouteUrl("Tutorial", new { @action = "ShowView", @viewName="Sample_Block"}) %>">Block</a>
                </li>
                <li>
                <a target="ifmMain" href="<%: this.Url.RouteUrl("Tutorial", new { @action = "ShowView", @viewName="Sample_Message"}) %>">Message</a>
                </li>
                <li>
                <a target="ifmMain" href="<%: this.Url.RouteUrl("Tutorial", new { @action = "ShowView", @viewName="Sample_Button"}) %>">Button</a>
                </li>
                <li>
                <a target="ifmMain" href="<%: this.Url.RouteUrl("Tutorial", new { @action = "ShowView", @viewName="Sample_LinkButton"}) %>">Link Button</a>
                </li>
                <li>
                <a target="ifmMain" href="<%: this.Url.RouteUrl("Tutorial", new { @action = "ShowView", @viewName="Sample_TextboxEx"}) %>">TextboxEx</a>
                </li>
                <li>
                <a target="ifmMain" href="<%: this.Url.RouteUrl("Tutorial", new { @action = "ShowView", @viewName="Sample_InputField"}) %>">Input Field</a>
                </li>
                <li>
                <a target="ifmMain" href="<%: this.Url.RouteUrl("Tutorial", new { @action = "ShowView", @viewName="Sample_InputField_RTL"}) %>">Input Field(R-t-L)</a>
                </li>
                <li>
                <a target="ifmMain" href="<%: this.Url.RouteUrl("Tutorial", new { @action = "ShowView", @viewName="Sample_SelectableTable"}) %>">Selectable Table</a>
                </li>
                <li>
                <a target="ifmMain" href="<%: this.Url.RouteUrl("Tutorial", new { @action = "ShowView", @viewName="Sample_SelectableTable_RTL"}) %>">Selectable Table(R-t-L)</a>
                </li>
                <li>
                <a target="ifmMain" href="<%: this.Url.RouteUrl("Tutorial", new { @action = "ShowView", @viewName="Sample_SideMenu"}) %>">Side Menu</a>
                </li>
                <li>
                <a target="ifmMain" href="<%: this.Url.RouteUrl("Tutorial", new { @action = "ShowView", @viewName="Sample_Tabs"}) %>">Tab</a>
                </li>
                <li>
                <a target="ifmMain" href="<%: this.Url.RouteUrl("Tutorial", new { @action = "ShowView", @viewName="Sample_Tabs_RTL"}) %>">Tab(Right-to-Left)</a>
                </li>
            </ul>
        </td>
        <td style="width:80%" align="center" valign="top">
            <iframe id="ifmMain" name="ifmMain" frameborder="1" style="width:95%; height:95%;" height="95%"></iframe>
        </td>
    </tr>
</table>

<script language="javascript" type="text/javascript">
function onWndResize(){
    $('#ifmMain').css('height', ($(document.body).height() - 20).toString(10) + "px");
}
$(document).ready(
    function () {
        onWndResize();
        $(window).resize(onWndResize);
    }
);
</script>
</body>
</html>



