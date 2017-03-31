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
     .button 
     {
         height:36px;
         border:none;
         padding:0px;
         margin: 0px;
         cursor:pointer;
         overflow:visible;
         zoom:1;
         background-color:transparent;         
     }
     .button .button_Right 
     {
         margin: 0px;
         padding:0px;
         width:100%;         
         height:36px;
         background-image:url("<%= this.ViewData["__client_base_path"] %>img/button.png");
         background-repeat:no-repeat;
         background-position: right -72px;
         display:block;
     }
     .button .button_Left
     {
         margin: 0px 8px 0px 0px;
         padding:0px;
         height:36px;
         background-image:url("<%= this.ViewData["__client_base_path"] %>img/button.png");
         background-repeat:no-repeat;
         background-position:left 0px;
         display:block;
     }
     .button .button_Center
     {
         margin:0px 0px 0px 8px;
         padding:0px;
         height:36px;
         background-image:url("<%= this.ViewData["__client_base_path"] %>img/button.png");
         background-repeat:repeat-x;
         background-position:left -36px;
         display:block;
     }
     .button .button_Center span 
     {
         color:#FFFFFF; 
         font-weight:600;
         height:36px; 
         margin:0px; 
         padding:0px; 
         line-height:35px; 
         vertical-align:middle; 
         white-space:nowrap;
         overflow:hidden;
     }

     
     /*******************************************************/
     .button:hover .button_Right { background-position: right -180px; }
     .button:hover .button_Left { background-position: left -108px; }
     .button:hover .button_Center { background-position: left -144px; }
     
     /*******************************************************/
     .loading_Spin .button_Center span
     {
         padding-right:20px !important;
         background-image:url(<%= this.ViewData["__client_base_path"] %>img/loading_spin.gif);
         background-position:right center;
         background-repeat:no-repeat;
     }
     .loading_Spin .button_Right { background-position: right -72px !important; }
     .loading_Spin .button_Left { background-position: left -0px !important; }
     .loading_Spin .button_Center { background-position: left -36px !important; }
    </style>
</head>


<body>

<div id="wrapper">
<ui:Button runat="server" Text="<%$ Metadata:value(.Title) %>" />
<br />
<%: Html.Button(this.GetMetadata(".Toggle_Btn_Text"), new { @id = "btnSave" })%>

</div>
<br />
<hr />

<table class="table-info" cellpadding="0" cellspacing="0" border="1" rules="all">
    <tr class="alternate-row">
        <td class="col-1">Server tag sample</td>
        <td class="col-2"><pre>&lt;ui:Button runat="server" Text="&lt;%$ Metadata:value(.Title) %&gt;" /&gt;</pre></td>
    </tr>
    <tr>
        <td class="col-1">Server script sample</td>
        <td class="col-2"><pre>&lt;%: Html.Button(this.GetMetadata(".Toggle_Btn_Text"), new { @id = "btnSave" })%&gt;</pre></td>
    </tr>
    <tr class="alternate-row">
        <td class="col-1">Client HTML sample</td>
        <td class="col-2"><pre id="client-html"></pre></td>
    </tr>
    <tr>
        <td class="col-1">Client CSS sample</td>
        <td class="col-2"><pre id="client-css"></pre></td>
    </tr>
    <tr class="alternate-row">
        <td class="col-1">Client Script sample</td>
        <td class="col-2"><pre>
$('#btnSave').toggleLoadingSpin(true).click(function () {
    $(this).toggleLoadingSpin();
});</pre></td>
    </tr>
</table>

    

<ui:ExternalJavascriptControl runat="server">
<script language="javascript" type="text/javascript">
    $(document).ready(
    function () {
        $('#client-html').text($('#wrapper').html());
        $('#client-css').text($('#style').html());

        $('#btnSave').click(function () {
            $(this).toggleLoadingSpin();
            setTimeout(function () {
                $('#btnSave').toggleLoadingSpin(false);
            }, 30000);
        });
    }
);
</script>
</ui:ExternalJavascriptControl>

</body>
</html>



