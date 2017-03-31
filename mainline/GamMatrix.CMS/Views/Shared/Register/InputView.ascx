<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<div class="register-input-view">
    <div class="form-wrapper">
    <% using (Html.BeginRouteForm("Register", new { @action = "Register" }, FormMethod.Post, new { @id = "formRegister" }))
       { %>
        
        <%Html.RenderPartial("/ExternalLogin/QuickSignup", this.ViewData.Merge(new { Type = "Register" }));%>

<%: Html.H2( this.GetMetadata(".Personal_Information") ) %>
<ui:Block runat="server" CssClass="reg_Panel">
    <% Html.RenderPartial("PersionalInformation", this.ViewData);  %>
</ui:Block>

<%: Html.H2(this.GetMetadata(".Address_Information"))%>
<ui:Block runat="server" CssClass="reg_Panel">
    <% Html.RenderPartial("AddressInformation", this.ViewData);  %>
</ui:Block>

<%: Html.H2(this.GetMetadata(".Account_Information"))%>
<ui:Block runat="server" CssClass="reg_Panel">
    <% Html.RenderPartial("AccountInformation", this.ViewData);  %>
</ui:Block>
<%if (Settings.Registration.IsCaptchaRequired)
    { %>
    <% Html.RenderPartial("/Components/RegisterCaptcha", this.ViewData);  %>
<%} %>
<% Html.RenderPartial("AdditionalInformation", this.ViewData);  %>
        <%if (Settings.IovationDeviceTrack_Enabled)
            { %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
        <%} %>

    <div class="button-wrapper">
    <%: Html.Button(this.GetMetadata(".Register_Button"), new { @type= "submit", @id = "btnRegisterUser"})%>
    </div>
<% } %>
    </div>
    <div class="advert-wrapper">
        <% Html.RenderPartial("Advertisement", this.ViewData); %>
    </div>
    <div class="clear"></div>
</div>

<% Html.RenderPartial("InputViewScript", this.ViewData); %>