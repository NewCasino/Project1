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
        #wrapper { width:95%; margin: 0 auto; clear:both; border:dotted 1px #000000; padding:10px; }
    </style>

    <style type="text/css" id="style">
        .h1 { height:32px; margin:0px; padding:0px; }
        .h1 .h1_Right 
        {
            height:32px;
            overflow:hidden;
            background-position:right 0px; 
            background-repeat:no-repeat; 
            background-image:url("<%= this.ViewData["__client_base_path"] %>img/header.png");
        }
        .h1 .h1_Left 
        {
            height:32px;
            overflow:hidden;
            margin-right:10px;
            background-position:0px -32px; 
            background-repeat:no-repeat; 
            background-image:url("<%= this.ViewData["__client_base_path"] %>img/header.png");
        }
        .h1 .h1_Middle 
        {
            height:32px; 
            overflow:hidden;
            margin-left:10px;
            background-position:0px -64px; 
            background-repeat:repeat-x; 
            background-image:url("<%= this.ViewData["__client_base_path"] %>img/header.png");
        }
        .h1 span { color:White; font-size:20px; line-height:32px; vertical-align:middle; }
        
        /**********************************************/
        
        .h2 { height:32px; margin:0px; padding:0px; }
        .h2 .h2_Right 
        {
            height:32px;
            overflow:hidden;
            background-position:right -96px; 
            background-repeat:no-repeat; 
            background-image:url("<%= this.ViewData["__client_base_path"] %>img/header.png");
        }
        .h2 .h2_Left 
        {
            height:32px;
            overflow:hidden;
            margin-right:10px;
            background-position:0px -128px; 
            background-repeat:no-repeat; 
            background-image:url("<%= this.ViewData["__client_base_path"] %>img/header.png");
        }
        .h2 .h2_Middle 
        {
            height:32px; 
            overflow:hidden;
            margin-left:10px;
            background-position:0px -160px; 
            background-repeat:repeat-x; 
            background-image:url("<%= this.ViewData["__client_base_path"] %>img/header.png");
        }
        .h2 span { color:White; font-size:18px; line-height:32px; vertical-align:middle; }
    </style>
</head>


<body>

<div id="wrapper">
<ui:Header HeadLevel="h1" runat="server" Text="<%$ Metadata:value(.Title) %>" />
<br />
<ui:Header HeadLevel="h2" runat="server">
Standard HTML components - <em>Header</em>
</ui:Header>

<div dir="rtl">
<br />
<%: Html.H1(this.GetMetadata(".Title")) %>
<br />
<%: Html.H2(this.GetMetadata(".Title")) %>
</div>


<%: Html.H3(this.GetMetadata(".Title")) %>

<%: Html.H4(this.GetMetadata(".Title")) %>

<%: Html.H5(this.GetMetadata(".Title")) %>

</div>
<br />
<hr />

<table class="table-info" cellpadding="0" cellspacing="0" border="1" rules="all">
    <tr class="alternate-row">
        <td class="col-1">Server tag sample</td>
        <td class="col-2"><pre>
&lt;ui:Header HeadLevel="h1" runat="server" Text="&lt;%$ Metadata:value(.Title) %&gt;" /&gt;

&lt;ui:Header HeadLevel="h2" runat="server"&gt;
Standard HTML components - &lt;em&gt;Header&lt;/em&gt;
&lt;/ui:Header&gt;</pre></td>
    </tr>
    <tr>
        <td class="col-1">Server script sample</td>
        <td class="col-2"><pre>
&lt;%: Html.H1(this.GetMetadata(".Title")) %&gt;
&lt;%: Html.H2(this.GetMetadata(".Title")) %&gt;
&lt;%: Html.H3(this.GetMetadata(".Title")) %&gt;
&lt;%: Html.H4(this.GetMetadata(".Title")) %&gt;
&lt;%: Html.H5(this.GetMetadata(".Title")) %&gt;</pre></td>
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



