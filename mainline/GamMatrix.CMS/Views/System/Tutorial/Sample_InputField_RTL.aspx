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
        #wrapper { width:95%; margin: 0 auto; clear:both; border:dotted 1px #000000; padding:10px;}
    </style>

    <style type="text/css" id="style">
    form { position:relative; } /* the popup hint is absolute positioning, so the form must be relative positioning */
    
    .inputfield { overflow:auto; zoom:1; vertical-align:top; margin-bottom:10px; }
    .inputfield .inputfield_Label { float:right; font-weight:600; clear:both; width:100%;}
    .inputfield .inputfield_Container { float:right; clear:both; }
    .inputfield .inputfield_Container .inputfield_Table { width:1%; display:block; }
    .inputfield .inputfield_Container .inputfield_Table .controls { width:1%; }
    .inputfield .inputfield_Error { color:Red; width:100%; }
    
    /* the indicator */
    .inputfield .inputfield_Container .inputfield_Table .indicator div 
    {
        margin-left:5px; margin-top:5px; margin-right:5px; width:16px; height:16px; 
        background-image:url("<%= this.ViewData["__client_base_path"] %>img/inputfield.png");
        background-repeat:repeat; background-position: -32px 0px;
    }
    .hide_default div { visibility:hidden; }
    .correct .inputfield_Container .inputfield_Table .indicator div { background-position: -16px 0px !important; visibility:visible !important; }
    .incorrect .inputfield_Container .inputfield_Table .indicator div { background-position: 0px 0px !important; visibility:visible !important; }
    .validating .inputfield_Container .inputfield_Table .indicator div { background-image:url("<%= this.ViewData["__client_base_path"] %>img/validating.gif") !important; visibility:visible !important; }
    .inputfield .inputfield_Container .inputfield_Table .hint { color:#666666; }

    .inputfield-tooltip { width:291px; background-image:url(img/red_message_box.png); background-repeat:no-repeat; background-position:0 0;}
    .inputfield-tooltip div { margin:5px 10px 10px 20px; width:261px; display:block; white-space:normal; color:Red; font-size:14px; font-family:Verdana; }

    .inputfield .controls .password { border: 1px solid #D9D9D9; padding: 3px 3px 3px 3px; width:300px; background-color:#FFFFFF; }
    .inputfield .controls .textbox { border: 1px solid #D9D9D9; padding: 3px 3px 3px 3px; width:300px; background-color:#FFFFFF; }
    .inputfield .controls .select { border: 1px solid #D9D9D9; padding: 3px 0px 3px 0px; width:308px }

    
    
    /***********************************************/
    .bubbletip { position:absolute; top:0px; right:0px; display:none; }
    .bubbletip .bubbletip_Wrap{ position:relative; }
    .bubbletip .bubbletip_Container 
    {
        z-index:100;
        position:absolute;
        width:220px; overflow:hidden;  background-repeat:no-repeat;
        background-image:url("<%= this.ViewData["__client_base_path"] %>img/bubble.png");
        background-position: 0px 0px; 
    }
    .bubbletip .bubbletip_Container_Bottom
    {
        margin-top:5px; width:100%; overflow:hidden; background-repeat:no-repeat;
        background-image:url("<%= this.ViewData["__client_base_path"] %>img/bubble.png");
        background-position: -220px bottom;
    }
    .bubbletip .bubbletip_Container_Center
    {
        margin-bottom:5px; width:100%; overflow:hidden; background-repeat:repeat-y; min-height:15px;
        background-image:url("<%= this.ViewData["__client_base_path"] %>img/bubble.png");
        background-position: -440px 0px;
    }
    .bubbletip .inputfield_Error{ color:#000000 !important; margin-left:10px; margin-right:10px; }
    .bubbletip_Wrap .bubbletip_Arrow 
    {
        background-image:url("<%= this.ViewData["__client_base_path"] %>img/bubble.png");
        position:absolute;
        background-repeat:no-repeat;
        z-index:101;
    }
    .left .bubbletip_Wrap .bubbletip_Arrow 
    {
        width:14px;
        height:12px;
        background-position:-688px top;
        right:0px;
        top:6px;
    }
    .left .bubbletip_Container { right:12px; top:0px; }
    .top .bubbletip_Wrap .bubbletip_Arrow 
    {
        width:14px;
        height:12px;
        background-position:-675px top;
        right:6px;
        top:0px;
    }
    .top .bubbletip_Container { right:0px; top:10px; }
    </style>
</head>


<body dir="rtl">

<div id="wrapper">

    <% using (Html.BeginRouteForm( "Tutorial" // The route name
               , new { @action="RouteName" } // the action name
               , FormMethod.Post
               , new { id = "formDemo"} // the form id
               ) )
           { %>
    <ui:InputField runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".Firstname_Label").SafeHtmlEncode() %></LabelPart>
        <ControlPart>
        <%: Html.TextBox( "firstname", string.Empty, new 
        {
            @id = "txtFirstname",
            @validator = ClientValidators.Create().Required(this.GetMetadata(".Firstname_Empty"))
        }
                ) %>
        </ControlPart>
        <HintPart><%= this.GetMetadata(".Firstname_Hint").SafeHtmlEncode() %></HintPart>
    </ui:InputField>

    <ui:InputField runat="server">
        <LabelPart><%= this.GetMetadata(".MiddleName_Label").SafeHtmlEncode() %></LabelPart>
        <ControlPart>
        <%: Html.TextBox( "middlename", string.Empty, new 
        {
            @id = "txtMiddleName"
        }
        ) %>
        </ControlPart> 
        <HintPart><%= this.GetMetadata(".MiddleName_Hint").SafeHtmlEncode() %></HintPart>
    </ui:InputField>

    <ui:InputField runat="server" ShowDefaultIndicator="true">
        <LabelPart><%= this.GetMetadata(".Lastname_Label").SafeHtmlEncode() %></LabelPart>
        <ControlPart>
        <%: Html.TextBox( "lastname", string.Empty, new 
        {
            @id = "txtLastname",
            @validator = ClientValidators.Create().Required(this.GetMetadata(".Lastname_Empty"))
        }
                ) %>
        </ControlPart> 
    </ui:InputField>

    <ui:InputField runat="server" ShowDefaultIndicator="true">
        <LabelPart><%= this.GetMetadata(".Username_Label").SafeHtmlEncode() %></LabelPart>
        <ControlPart>
        <%: Html.TextBox( "username", string.Empty, new 
        {
            @id = "txtUsername",
            @validator = ClientValidators.Create().Required(this.GetMetadata(".Username_Empty")).Server(this.Url.RouteUrl("Tutorial", new { @action = "ValidateUsername" }))
        }
                ) %>
        </ControlPart> 
        <HintPart><%= this.GetMetadata(".Username_Hint").SafeHtmlEncode() %></HintPart>
    </ui:InputField>

    <ui:InputField runat="server" >
        <LabelPart><%= this.GetMetadata(".Password_Label").SafeHtmlEncode() %></LabelPart>
        <ControlPart>
        <%: Html.TextBox( "password", string.Empty, new 
        {
            @id = "txtPassword",
            @type = "password",
            @validator = ClientValidators.Create().Required(this.GetMetadata(".Password_Empty"))
        }
                ) %>
        </ControlPart> 
    </ui:InputField>

    <ui:InputField ID="InputField1" runat="server" >
        <LabelPart><%= this.GetMetadata(".Title_Label").SafeHtmlEncode() %></LabelPart>
        <ControlPart>
        <% var titleList = new List<SelectListItem>();
           titleList.Add(new SelectListItem() { Text = "Mr.", Value = "Mr." }); %>
        <%: Html.DropDownList("title", titleList, new 
        {
            @id = "txtTitle",
            @validator = ClientValidators.Create().Required(this.GetMetadata(".Title_Empty"))
        }
                ) %>
        </ControlPart> 
    </ui:InputField>
    <% } %>

    <%: Html.Button("Validate the form", new { @id = "btnValidateForm" }) %>
</div>

<br />
<hr />

<table class="table-info" cellpadding="0" cellspacing="0" border="1" rules="all">
    <tr class="alternate-row">
        <td class="col-1">Server tag sample</td>
        <td class="col-2"><pre>
&lt;ui:InputField runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left"&gt;
	&lt;LabelPart&gt;&lt;%= this.GetMetadata(".Firstname_Label").SafeHtmlEncode() %&gt;&lt;/LabelPart&gt;
	&lt;ControlPart&gt;
		&lt;%: Html.TextBox( "firstname", string.Empty, new 
		{
		    @id = "txtFirstname",
		    @validator = ClientValidators.Create().Required(this.GetMetadata(".Firstname_Empty"))
		}
			) %&gt;
	&lt;/ControlPart&gt;
	&lt;HintPart&gt;&lt;%= this.GetMetadata(".Firstname_Hint").SafeHtmlEncode() %&gt;&lt;/HintPart&gt;      
&lt;/ui:InputField&gt;</pre></td>
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
    function onVal() {
        var value = this;
        if (value == '1')
            return true; 
        return "Error: invalid lastname";
    }

    $(document).ready(
    function () {
        $('#client-html').text($('#wrapper').html());
        $('#client-css').text($('#style').html());


        // initialize the form
        $("#formDemo").initializeForm();

        // hook the button click event to validate the form
        $('#btnValidateForm').click(function () {
            alert($('#formDemo').valid());
        });

    }
);
</script>
</ui:ExternalJavascriptControl>

</body>
</html>



