<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<% using (Html.BeginRouteForm("Register", new { @action = "Register" }, FormMethod.Post, new { @id = "formRegister" }))
   { %>

<div class="register-input-view">
    <div class="form-wrapper">
        <%Html.RenderPartial("/ExternalLogin/QuickSignup", this.ViewData.Merge(new { Type = "Register" }));%>

        <ui:Block runat="server" CssClass="reg_Panel">
            <%: Html.H2( this.GetMetadata(".Personal_Information") ) %>
            <% Html.RenderPartial("PersionalInformation", this.ViewData);  %>
        </ui:Block>

        <ui:Block runat="server" CssClass="reg_Panel">
            <%: Html.H2(this.GetMetadata(".Address_Information"))%>
            <% Html.RenderPartial("AddressInformation", this.ViewData);  %>
        </ui:Block>

        <ui:Block runat="server" CssClass="reg_Panel">
            <%: Html.H2(this.GetMetadata(".Account_Information"))%>
            <% Html.RenderPartial("AccountInformation", this.ViewData);  %>
        </ui:Block>

        <% Html.RenderPartial("AdditionalInformation", this.ViewData);  %>

        <div class="button-wrapper">
            <%: Html.Button(this.GetMetadata(".Register_Button"), new { @type= "submit", @id = "btnRegisterUser"})%>
        </div>
    </div>
    <div class="advert-wrapper">
        <% Html.RenderPartial("Advertisement", this.ViewData); %>
    </div>
    <div class="clear"></div>
</div>
<% } %>

<% Html.RenderPartial("InputViewScript", this.ViewData); %>