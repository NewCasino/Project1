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
     .linkbutton { height:19px; display:inline-block; color:White; zoom:1; text-decoration:none; cursor:pointer; }
     .linkbutton .linkbutton_Right 
     {
         height:19px;
         background-image:url("<%= this.ViewData["__client_base_path"] %>img/linkbutton.png");
         background-repeat:no-repeat;
         background-position: right -20px;
         display:block;
     }
     .linkbutton .linkbutton_Left
     {
         margin-right:11px;
         height:19px;
         background-image:url("<%= this.ViewData["__client_base_path"] %>img/linkbutton.png");
         background-repeat:no-repeat;
         background-position: left top;
         display:block;
     }
     .linkbutton .linkbutton_Center
     {
         margin-left:11px;
         height:19px;
         background-image:url("<%= this.ViewData["__client_base_path"] %>img/linkbutton.png");
         background-repeat:repeat-x;
         background-position: left -40px;
         display:block;
     }
     .linkbutton .linkbutton_Center span
     {
         white-space:nowrap;
         height:100%;
         padding:0px;
         margin:0px;
         line-height:19px;
         vertical-align:middle;   
         display:block;               
     }
     
     /************************************************/
     .linkbutton:hover { text-decoration:underline; }
     .linkbutton:hover .linkbutton_Right { background-position: right -80px; }
     .linkbutton:hover .linkbutton_Left  { background-position: left -60px; }
     .linkbutton:hover .linkbutton_Center { background-position: left -100px; }
    </style>
</head>


<body>

<div id="wrapper">
<ui:LinkButton runat="server" Text="<%$ Metadata:value(.LINK_TEXT) %>" />
<br /><br />
<%: Html.LinkButton(this.GetMetadata(".LINK_TEXT"), new { @href = "http://www.google.com", @target="_blank"})%>
</div>
<br />
<hr />

<table class="table-info" cellpadding="0" cellspacing="0" border="1" rules="all">
    <tr class="alternate-row">
        <td class="col-1">Server tag sample</td>
        <td class="col-2"><pre>&lt;ui:LinkButton runat="server" Text="&lt;%$ Metadata:value(.LINK_TEXT) %&gt;" /&gt;</pre></td>
    </tr>
    <tr>
        <td class="col-1">Server script sample</td>
        <td class="col-2"><pre>&lt;%: Html.LinkButton(this.GetMetadata(".LINK_TEXT"), new { @href = "http://www.google.com", @target="_blank"})%&gt;</pre></td>
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



