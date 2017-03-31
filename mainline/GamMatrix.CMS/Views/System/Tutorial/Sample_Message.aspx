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
     .message { width:500px; height:80px; margin:0 auto; clear:both; overflow:hidden; }
     .message .message_Table 
     {
         border-collapse:collapse; width:100%; height:100%; table-layout:fixed;
     }
     .message .message_Col_Icon { width:20%; }
     .message .message_Col_Text { width:80%; text-align:center; }
     .message .message_Icon 
     {
         width:48px; height:48px; overflow:hidden; 
         background-image:url("<%= this.ViewData["__client_base_path"] %>img/standard_icons.png"); 
     }
     /******************************************/
     .information .message_Table { background-color:#BDE5F8; border:solid 1px #00529B; }
     .information .message_Icon { background-position: 0px 0px; }
     .information .message_Text { color:#000099; }
     
     .success .message_Table { background-color:#DFF2BF; border:solid 1px #4F8A10; }
     .success .message_Icon { background-position: -48px 0px; }
     .success .message_Text { color:#006600; }
     
     .warning .message_Table { background-color:#FEEFB3; border:solid 1px #9F6000; }
     .warning .message_Icon { background-position: -96px 0px; }
     .warning .message_Text { color:#9F6000; }
     
     .error .message_Table { background-color:#FFBABA; border:solid 1px #D8000C; }
     .error .message_Icon { background-position: -144px 0px; }
     .error .message_Text { color:#990000; }
    </style>
</head>


<body>

<div id="wrapper">
<%: Html.SuccessMessage( this.GetMetadata(".Title") ) %>
<br />
<%: Html.ErrorMessage( this.GetMetadata(".Title") ) %>
<br />
<%: Html.WarningMessage( this.GetMetadata(".Title"), false ) %>
<br />
<%: Html.InformationMessage( this.GetMetadata(".Title"), false ) %>
<br />

<div dir="rtl">
<ui:Message ID="Message1" runat="server" Text="<%$ Metadata:value(.Title) %>" Type="Information" />
<br />
<ui:Message ID="Message2" runat="server" Text="<%$ Metadata:value(.Title) %>" Type="Error" />
<br />
<ui:Message ID="Message3" runat="server" Text="<%$ Metadata:value(.Title) %>" Type="Warning" />
<br />
<ui:Message ID="Message4" runat="server" Text="<%$ Metadata:value(.Title) %>" Type="Success" />
<br />
</div>
</div>
<br />
<hr />

<table class="table-info" cellpadding="0" cellspacing="0" border="1" rules="all">
    <tr class="alternate-row">
        <td class="col-1">Server tag sample</td>
        <td class="col-2"><pre>&lt;ui:Message runat="server" Text="&lt;%$ Metadata:value(.Title) %&gt;" Type="Information" /&gt;
&lt;ui:Message runat="server" Text="&lt;%$ Metadata:value(.Title) %&gt;" Type="Error" /&gt;
&lt;ui:Message runat="server" Text="&lt;%$ Metadata:value(.Title) %&gt;" Type="Warning" /&gt;
&lt;ui:Message runat="server" Text="&lt;%$ Metadata:value(.Title) %&gt;" Type="Success" /&gt;</pre></td>
    </tr>
    <tr>
        <td class="col-1">Server script sample</td>
        <td class="col-2"><pre>&lt;%: Html.SuccessMessage( this.GetMetadata(".Title") ) %&gt;
&lt;%: Html.ErrorMessage( this.GetMetadata(".Title") ) %&gt;
&lt;%: Html.WarningMessage( this.GetMetadata(".Title"), false ) %&gt;
&lt;%: Html.InformationMessage( this.GetMetadata(".Title"), false ) %&gt;</pre></td>
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



