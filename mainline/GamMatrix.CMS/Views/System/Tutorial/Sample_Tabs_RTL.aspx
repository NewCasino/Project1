<%@ Page Title="<%$ Metadata:value(.Title) %>" Language="C#" Inherits="CM.Web.ViewPageEx<dynamic>"%>

<%@ Import Namespace="CM.Web.UI" %>

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
    .tabbed_content { width:90%; margin:0 auto; }
    .tabbed_content .tabs { height:32px; width:100%; margin:0px; padding:0px; overflow:hidden; }
    .tabbed_content .tabs .tab { float:right; padding:0px; margin:0px 0px 0px 5px; height:100%; display:inline-block; }
    .tabbed_content .tab a { text-decoration:none; }
    .tabbed_content .tab .tab_left { height:100%; background:url("<%= this.ViewData["__client_base_path"] %>img/tab_head.png") no-repeat scroll left -102px; }
    .tabbed_content .tab .tab_right { height:100%; margin-left:7px; background:url("<%= this.ViewData["__client_base_path"] %>img/tab_head.png") no-repeat scroll right -170px; }
    .tabbed_content .tab .tab_center { height:100%; margin-right:7px; background:url("<%= this.ViewData["__client_base_path"] %>img/tab_head.png") repeat-x scroll right -136px; }
    .tabbed_content .tab_center span { line-height:32px; color:White; vertical-align:middle; font-weight:bold; cursor:pointer; }
    
    .tabbed_content .selected .tab_left { background:url("<%= this.ViewData["__client_base_path"] %>img/tab_head.png") no-repeat scroll left top !important; }
    .tabbed_content .selected .tab_right { background:url("<%= this.ViewData["__client_base_path"] %>img/tab_head.png") no-repeat scroll right -68px !important; }
    .tabbed_content .selected .tab_center {background:url("<%= this.ViewData["__client_base_path"] %>img/tab_head.png") repeat-x scroll right -34px !important; }
    .tabbed_content .selected .tab_center span { color:Black !important; }
    
    .tabbed_content .tabbody { width:100%; }
    .tabbed_content .tabbody .tabbody_Center_Right { width:100%; height:auto; overflow:hidden; background-color:#C6C6C6; }
    .tabbed_content .tabbody .tabbody_Center_Left { margin-right:5px; background-color:#C6C6C6; height:auto; overflow:hidden; }
    .tabbed_content .tabbody .tabbody_Center_Middle { color:#000000; margin-left:5px; background-color:#C6C6C6; height:auto; overflow:hidden; padding:5px; }
    .tabbed_content .tabbody .tabbody_Bottom { clear:both; width:100%; height:6px; position:relative; }
    .tabbed_content .tabbody .tabbody_Bottom_Right { position:absolute; top:0px; right:0px; width:55%; height:6px; overflow:hidden; background:url("<%= this.ViewData["__client_base_path"] %>img/tabbody_bottom.png") no-repeat scroll right top;
    }
    .tabbed_content .tabbody .tabbody_Bottom_Left { position:absolute; top:0px; left:0px; width:55%; height:6px; overflow:hidden; background:url("<%= this.ViewData["__client_base_path"] %>img/tabbody_bottom.png") no-repeat scroll left top;
    }
    </style>
</head>


<body dir="rtl">


<div id="wrapper">

<ui:TabbedContent runat="server">
    <Tabs>
        <ui:Panel runat="server" ID="tabRegister" Selected="true" Caption="Register a Card">
           <p>Lorem ipsum dolor sit amet, consecte adipiscing elit. Praesentporttitor dolor et mauris blandit in imperdiet nunc ultricies. Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. 
           Sed moles mi vel dui ultrices tempus mollis ante ultrices. Vestibulum ante ipsum primis in faucibus orci mauris blandit in imperdiet nunc ultricies. Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. Sed moles mi vel dui ultrices tempus mollis ante ultrices. 
           Vestibulum ante ipsum primis in faucibus orci mauris blandit in imperdiet nunc ultricies. Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. Sed moles mi vel dui ultrices tempus mollis ante ultrices. Vestibulum ante ipsum primis in faucibus orci mauris blandit in imperdiet nunc ultricies. Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. </p>
        </ui:Panel>
        <ui:Panel runat="server" ID="tabExisting" Caption="Exiting Card">
          <p>Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. Sed moles mi vel dui ultrices tempus mollis ante ultrices. Vestibulum ante ipsum primis in faucibus orci mauris blandit in imperdiet nunc ultricies. Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum.</p>

<p>Lorem ipsum dolor sit amet, consecte adipiscing elit. Praesentporttitor dolor et mauris blandit in imperdiet nunc ultricies. Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. Sed moles mi vel dui ultrices tempus mollis ante ultrices. Vestibulum ante ipsum primis in faucibus orci mauris blandit .</p>
        </ui:Panel>
    </Tabs>
</ui:TabbedContent>

</div>
<br />
<hr />

<table class="table-info" cellpadding="0" cellspacing="0" border="1" rules="all">
    <tr class="alternate-row">
        <td class="col-1">Server tag sample</td>
        <td class="col-2"><pre>
&lt;ui:TabbedContent runat="server"&gt;
    &lt;Tabs&gt;
        &lt;ui:Panel runat="server" ID="tabRegister" Selected="true" Caption="Register a Card"&gt;
           &lt;p&gt;Lorem ipsum dolor sit amet, consecte adipiscing elit. Praesentporttitor dolor et mauris blandit in imperdiet nunc ultricies. 
           Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. Sed moles mi vel dui ultrices tempus mollis ante ultrices. 
           Vestibulum ante ipsum primis in faucibus orci mauris blandit in imperdiet nunc ultricies. Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. 
           Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. Sed moles mi vel dui ultrices tempus mollis ante ultrices. 
           Vestibulum ante ipsum primis in faucibus orci mauris blandit in imperdiet nunc ultricies. Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. 
           Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. Sed moles mi vel dui ultrices tempus mollis ante ultrices. 
           Vestibulum ante ipsum primis in faucibus orci mauris blandit in imperdiet nunc ultricies. Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. &lt;/p&gt;
        &lt;/ui:Panel&gt;
        &lt;ui:Panel runat="server" ID="tabExisting" Caption="Exiting Card"&gt;
          &lt;p&gt;Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. Sed moles mi vel dui ultrices tempus mollis ante ultrices. Vestibulum ante ipsum primis in faucibus orci mauris blandit in imperdiet nunc ultricies. 
          Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum.&lt;/p&gt;

&lt;p&gt;Lorem ipsum dolor sit amet, consecte adipiscing elit. Praesentporttitor dolor et mauris blandit in imperdiet nunc ultricies. Vivamus scelerisque purus eget nibh mattis ac tincidunt magna bibendum. Sed moles mi vel dui ultrices tempus mollis ante ultrices. Vestibulum ante ipsum primis in faucibus orci mauris blandit .&lt;/p&gt;
        &lt;/ui:Panel&gt;
    &lt;/Tabs&gt;
&lt;/ui:TabbedContent&gt;</pre></td>
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

    


<script language="javascript" type="text/javascript">
$(document).ready(
function () {
    $('#client-html').text($('#wrapper').html());
    $('#client-css').text($('#style').html());
}
);
</script>


</body>
</html>



