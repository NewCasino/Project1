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
        #wrapper { width:95%; margin: 0 auto; clear:both; border:dotted 1px #000000; padding:10px; background-color:#000000; }
    </style>

    <style type="text/css" id="style">
     .panel { width:100%; }
     .panel .panel_Center_Right
     {
         width:100%;
         background-image:url("<%= this.ViewData["__client_base_path"] %>img/panel_border_right.gif");
         background-repeat:repeat-y;
         background-position:right;
         height:auto;
         overflow:hidden;
     }
     .panel .panel_Center_Left
     {
         margin-right:5px;
         background-image:url("<%= this.ViewData["__client_base_path"] %>img/panel_border_left.gif");
         background-repeat:repeat-y;
         background-position:0px 0px;
         height:auto;
         overflow:hidden;
     }
     .panel .panel_Center_Middle
     {
         color:#FFFFFF;
         margin-left:5px;
         background-color:#1E4D5D;
         height:auto;
         overflow:hidden;
     }
     .panel .panel_Bottom
     {
         clear:both;
         width:100%;
         height:6px;
         position:relative;
     }
     .panel .panel_Bottom_Right
     {
         position:absolute;
         top:0px;
         right:0px;
         width:55%;
         height:6px;
         overflow:hidden;
         background-image:url("<%= this.ViewData["__client_base_path"] %>img/panel_bottom.png");
         background-repeat:no-repeat;
         background-position:right top;
     }
     .panel .panel_Bottom_Left
     {
         position:absolute;
         top:0px;
         left:0px;
         width:55%;
         height:6px;
         overflow:hidden;
         background-image:url("<%= this.ViewData["__client_base_path"] %>img/panel_bottom.png");    
         background-repeat:no-repeat; 
         background-position:left top;
     }
    </style>
</head>


<body>

<div id="wrapper">

<ui:Panel runat="server" ID="pnDemo">

<p>Lorem ipsum dolor sit amet, consecte adipiscing elit. Praesentporttitor dolor et mauris blandit in imperdiet nunc ultricies.  
 Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. Sed moles mi vel dui ultrices tempus mollis ante ultrices. 
 Vestibulum ante ipsum primis in faucibus orci mauris blandit in imperdiet nunc ultricies. Vivamus scelerisque purus eget nibh mattis 
 ac tincidunt magna bibendum. Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. Sed moles mi vel dui ultrices 
 tempus mollis ante ultrices. Vestibulum ante ipsum primis in faucibus orci mauris blandit in imperdiet nunc ultricies. 
 Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. Vivamus scelerisque purus eget nibh mattis ac 
 tincidunt magna bibendum. Sed moles mi vel dui ultrices tempus mollis ante ultrices. Vestibulum ante ipsum primis in 
 faucibus orci mauris blandit in imperdiet nunc ultricies. Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum.
 </p>
 <p>
 Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. Sed moles mi vel dui ultrices tempus mollis ante ultrices. 
 Vestibulum ante ipsum primis in faucibus orci mauris blandit in imperdiet nunc ultricies. Vivamus scelerisque purus eget nibh mattis 
 ac tincidunt magna bibendum.</p>
 <p>
 Lorem ipsum dolor sit amet, consecte adipiscing elit. Praesentporttitor dolor et mauris blandit in imperdiet nunc ultricies.  
 Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. Sed moles mi vel dui ultrices tempus mollis ante ultrices. 
 Vestibulum ante ipsum primis in faucibus orci mauris blandit .</p>
</ui:Panel>

</div>
<br />
<hr />

<table class="table-info" cellpadding="0" cellspacing="0" border="1" rules="all">
    <tr class="alternate-row">
        <td class="col-1">Server tag sample</td>
        <td class="col-2"><pre>
&lt;ui:Panel runat="server" ID="pnDemo"&gt;
    ...
&lt;/ui:Panel&gt;</pre></td>
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



