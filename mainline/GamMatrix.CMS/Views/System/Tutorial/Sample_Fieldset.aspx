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
     .fieldset fieldset 
     {
        border:solid 1px green;
        border-radius:5px;
        -moz-border-radius-topright:5px;
        -moz-border-radius-topleft:5px;
        -moz-border-radius-bottomright:5px;
        -moz-border-radius-bottomleft:5px;
        -webkit-border-top-right-radius:5px;
        -webkit-border-top-left-radius:5px;
        -webkit-border-bottom-right-radius:5px;
        -webkit-border-bottom-left-radius:5px;
     }
     .fieldset legend 
     {
        margin-left:50px;
        padding: 0.2em 0.5em;
        border:solid 1px green;
        color:green;
        font-size:12px;
        border-radius:5px;
        -moz-border-radius-topright:5px;
        -moz-border-radius-topleft:5px;
        -moz-border-radius-bottomright:5px;
        -moz-border-radius-bottomleft:5px;
        -webkit-border-top-right-radius:5px;
        -webkit-border-top-left-radius:5px;
        -webkit-border-bottom-right-radius:5px;
        -webkit-border-bottom-left-radius:5px;
     }
     .fieldset .fieldset_Container
     {
         margin:15px;
     }
    </style>
</head>


<body>

<div id="wrapper">

<ui:Fieldset runat="server" ID="fsDemo" Legend="<%$ Metadata:value(.Title) %>">
    <input type="text" />
    <br /><br />
    <input type="text" />
</ui:Fieldset>

</div>
<br />
<hr />

<table class="table-info" cellpadding="0" cellspacing="0" border="1" rules="all">
    <tr class="alternate-row">
        <td class="col-1">Server tag sample</td>
        <td class="col-2"><pre>
&lt;ui:Fieldset runat="server" ID="fsDemo" Legend="&lt;%$ Metadata:value(.Title) %&gt;"&gt;
    ...
&lt;/ui:Fieldset&gt;</pre></td>
    </tr>
    <tr>
        <td class="col-1">Server script sample</td>
        <td class="col-2"><pre> </pre></td>
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



