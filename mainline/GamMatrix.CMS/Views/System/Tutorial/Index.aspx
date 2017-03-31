<%@ Page Language="C#" PageTemplate="/Content.master" Inherits="CM.Web.ViewPageEx<dynamic>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/Tutorial/Index.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="tutorial-wrapper">
<div class="content">
    <div class="header">
    <h2><%= this.GetMetadata(".Title") %></h2>
    </div>

    <img style="margin:10px" src="/App_Themes/AdminConsole/img/help_intro.png" />
</div>
</div>

</asp:Content>

