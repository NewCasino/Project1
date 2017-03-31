<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <div id="register-wrapper" class="content-wrapper">
        <div class="DialogHeader">
            <span class="DialogIcon">ArtemisBet</span>
            <h3 class="DialogTitle"><%= this.GetMetadata(".LoginDialogTitle") %></h3>
        </div>
        <strong class="QROffer"><%= this.GetMetadata(".QROffer") %></strong>
        <ui:Panel runat="server" ID="pnRegister">
        <%
            if (Profile.IsAuthenticated)
                Response.Redirect( this.Url.RouteUrl( "Deposit", new { @action="Index" }), false );// logged in
            else
                Html.RenderPartial("/QuickRegister/InputView");    
        %>
        </ui:Panel>
        <div class="landing_register_bottom"><img src="<%= this.GetMetadata(".BottomImage") %>" /></div>
    </div>
</asp:Content>

