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
        #wrapper { width:95%; margin: 0 auto; clear:both; border:dotted 1px #000000; padding:10px; background-color:#3C0505; }
    </style>

    <style type="text/css" id="style">
     .block { width: 100%; }
     .block .block_Top { width:100%; clear:both; height:26px; overflow:hidden; position:relative; }
     .block .block_Top_Left
     {
         position:absolute;
         top:0px;
         left:0px;
         height:26px;
         width:55%;
         background-repeat:no-repeat;
         background-image:url("<%= this.ViewData["__client_base_path"] %>img/block_top_bottom.png");
         background-position:left 0px;
     }
     .block .block_Top_Right
     {
         position:absolute;
         top:0px;
         right:0px;
         height:26px;
         width:55%;
         background-repeat:no-repeat;
         background-image:url("<%= this.ViewData["__client_base_path"] %>img/block_top_bottom.png");
         background-position:right 0px;
     }
     .block .block_Bottom { width:100%; clear:both; height:31px; overflow:hidden; position:relative; }
     .block .block_Bottom_Left
     {
         position:absolute;
         top:0px;
         left:0px;
         height:31px;
         width:55%;
         background-repeat:no-repeat;
         background-image:url("<%= this.ViewData["__client_base_path"] %>img/block_top_bottom.png");
         background-position:left -26px;
     }
     .block .block_Bottom_Right
     {
         position:absolute;
         top:0px;
         right:0px;
         height:31px;
         width:55%;
         background-repeat:no-repeat;
         background-image:url("<%= this.ViewData["__client_base_path"] %>img/block_top_bottom.png");
         background-position:right -26px;
     }
     
     .block .block_Center_Right
     {
         width:100%;
         height:auto;
         overflow:hidden;
         background-position:right;
         background-repeat:repeat-y;
         background-image:url("<%= this.ViewData["__client_base_path"] %>img/block_border_right.png");
     }
     .block .block_Center_Left
     {
         margin-right:31px;
         overflow:hidden;
         background-position:left;
         background-repeat:repeat-y;
         background-image:url("<%= this.ViewData["__client_base_path"] %>img/block_border_left.png");
     }
     .block .block_Center_Middle
     {
         overflow:hidden;
         margin-left:33px;
         color:Black;
         background-color:#F5F5F5;
     }
    </style>
</head>


<body>

<div id="wrapper">
<ui:Block runat="server">
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


</ui:Block>
</div>
<br />
<hr />

<table class="table-info" cellpadding="0" cellspacing="0" border="1" rules="all">
    <tr class="alternate-row">
        <td class="col-1">Server tag sample</td>
        <td class="col-2"><pre>
&lt;ui:Block runat="server"&gt;
	...
&lt;/ui:Block&gt;</pre></td>
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



