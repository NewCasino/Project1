<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<div class="register-input-view">
  <div class="form-wrapper">
    <% using (Html.BeginRouteForm("Register", new { @action = "Register" }, FormMethod.Post, new { @id = "formRegister" }))
       { %>
    <div class="holder-flex-100 registerTable TermsConditions ">
    <div class="ThreeCol FirstCol">
      <div class="Box FirstBox">
         <h2 class="TermsTitle"><%: this.GetMetadata(".Personal_Information") %></h2>
        <ui:Block ID="Block1" runat="server" CssClass="reg_Panel">
          <% Html.RenderPartial("PersionalInformation", this.ViewData);  %>
        </ui:Block>
      </div>
    </div>
    <div class="ThreeCol MiddleCol">
      <div class="Box MiddleBox">
        <h2 class="TermsTitle"><%: this.GetMetadata(".Address_Information")%></h2>
        <ui:Block ID="Block2" runat="server" CssClass="reg_Panel">
          <% Html.RenderPartial("AddressInformation", this.ViewData);  %>
        </ui:Block>
      </div>
    </div>
    <div class="ThreeCol LastCol">
      <div class="Box LastBox">
       <h2 class="TermsTitle"><%:this.GetMetadata(".Account_Information")%> </h2>
        <ui:Block ID="Block3" runat="server" CssClass="reg_Panel">
          <% Html.RenderPartial("AccountInformation", this.ViewData);  %>
        </ui:Block>
      </div>
    </div>
</div>
    <% Html.RenderPartial("AdditionalInformation", this.ViewData);  %>
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
<% Html.RenderPartial("InputViewScript", this.ViewData); %><ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
<script> 
    var PersonalIDErrorTxt = '<%= this.GetMetadata("/Register/_PersionalInformation_ascx.PersonalID_Illegal").SafeJavascriptStringEncode() %>'.format($('#fldPersonalID .inputfield_Label').text());
    function validatePersonalID() {
            if (__personalIdValidationRegularExpression == null || __personalIdValidationRegularExpression.length == 0)
                return true;
            var value = $("#txtPersonalID").val();
            var regex = new RegExp(__personalIdValidationRegularExpression, "g");
            var ret = regex.exec(value);
            if (ret == null || ret.length == 0)
                return PersonalIDErrorTxt;
        try {
            var ti = 0;
            for (var i = 0; i < 10 ; i++) {
                ti += parseInt(value.substr(i, 1));
            }
            if (ti % 10 != parseInt(value.substr(10, 1)))
                return PersonalIDErrorTxt;
        } catch (err) {
            return PersonalIDErrorTxt;
        }
        return true;
    } 
</script></ui:MinifiedJavascriptControl>
 