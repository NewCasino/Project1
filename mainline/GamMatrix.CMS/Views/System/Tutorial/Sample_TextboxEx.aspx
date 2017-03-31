<%@ Page Title="<%$ Metadata:value(.Title) %>" Language="C#" Inherits="CM.Web.ViewPageEx<dynamic>"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/combined.js") %>"></script>
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/inputfield.js") %>"></script>
    <style type="text/css">
        html, body { background-color:White; font-family:Consolas; font-size:12px; color:Black; font-style:normal; }
        .table-info { width:100%; border: solid 1px #B3CC82; }
        .table-info td { padding:5px; background-color:#E6EED5; }
        .table-info .alternate-row td { background-color:#CDDDAC !important; }
        .table-info .col-1 { font-weight:600; }
        #wrapper { width:95%; margin: 0 auto; clear:both; border:dotted 1px #000000; padding:10px; background-color:#627C93; }
    </style>

    <style type="text/css" id="style">
        .textboxex { display:inline-block; height:30px; background-repeat:no-repeat; background-position:left top; background-image:url("<%= this.ViewData["__client_base_path"] %>img/textboxex.png"); }
        .textboxex .textboxex_Right{ margin-left:8px; height:100%; background-repeat:no-repeat; background-position:right -62px; background-image:url("<%= this.ViewData["__client_base_path"] %>img/textboxex.png"); }
        .textboxex .textboxex_Center { margin-right:8px; height:100%; background-repeat:repeat-x; background-position:left -31px; background-image:url("<%= this.ViewData["__client_base_path"] %>img/textboxex.png"); }
        .textboxex input { outline:none; width:200px; padding:0xp; margin-top:5px; border:0px; height:20px; background-color:transparent; background-image:none; }
        
        .searchBox { display:inline-block; height:30px; background-repeat:no-repeat; background-position:left top; background-image:url("<%= this.ViewData["__client_base_path"] %>img/textboxex.png"); }
        .searchBox .searchBox_Right{ margin-left:8px; height:100%; background-repeat:no-repeat; background-position:right -93px; background-image:url("<%= this.ViewData["__client_base_path"] %>img/textboxex.png"); }
        .searchBox .searchBox_Center { margin-right:32px; height:100%; background-repeat:repeat-x; background-position:left -31px; background-image:url("<%= this.ViewData["__client_base_path"] %>img/textboxex.png"); }
        .searchBox input { outline:none; width:176px; padding:0xp; margin-top:5px; border:0px; height:20px; background-color:transparent; background-image:none; }

        .textboxex_wartermark { color:#666666 !important; }
    </style>
</head>


<body>

<div id="wrapper">

<%: Html.TextboxEx( "username", "", "Username") %>
<br /><br />
<%: Html.TextboxEx("password", "", "Password", new { @type = "password" })%>
<br /><br /><br /><br />
<%: Html.TextboxEx("keywords", "", "Search in Google", null, "searchBox")%>

</div>
<br />
<hr />

<table class="table-info" cellpadding="0" cellspacing="0" border="1" rules="all">
    <tr class="alternate-row">
        <td class="col-1">Server tag sample</td>
        <td class="col-2"><pre> </pre></td>
    </tr>
    <tr>
        <td class="col-1">Server script sample</td>
        <td class="col-2"><pre>&lt;%: Html.TextboxEx( "username", "", "Username") %&gt;

&lt;%: Html.TextboxEx("password", "", "Password", new { @type = "password" })%&gt;

&lt;%: Html.TextboxEx("keywords", "", "Search in Google", null, "searchBox")%&gt;</pre></td>
    </tr>
    <tr class="alternate-row">
        <td class="col-1">Client HTML sample</td>
        <td class="col-2"><pre id="client-html"></pre></td>
    </tr>
    <tr>
        <td class="col-1">Client CSS sample</td>
        <td class="col-2"><pre id="client-css"></pre></td>
    </tr>
   
</table>

    

<ui:ExternalJavascriptControl runat="server">
<script language="javascript" type="text/javascript">
    $(document).ready(
    function () {
        $('#client-html').text($('#wrapper').html());
        $('#client-css').text($('#style').html());
    }
);
</script>
</ui:ExternalJavascriptControl>

</body>
</html>



