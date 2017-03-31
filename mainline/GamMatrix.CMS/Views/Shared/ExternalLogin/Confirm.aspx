<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<CM.db.cmExternalLogin>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<%:Html.InformationMessage(this.GetMetadata(".Confirm")) %>
<% using (Html.BeginRouteForm("_ExternalLogin", new { @action = "ProcessAssociate" }, FormMethod.Post, new { @id = "formAssociate" }))
       { %>
    
    <%: Html.Hidden("referrerID", this.ViewData["referrerID"])%>
    <%: Html.Hidden("username", Profile.UserName)%>
    <%------------------------------------------
    Password
    -------------------------------------------%>
    <ui:InputField ID="fldPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	    <LabelPart><%= this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Password_Label").SafeHtmlEncode()%></LabelPart>
	    <ControlPart>
		    <%: Html.TextBox("password",null, new 
		    {
                @maxlength = 20,
                @id = "txtPassword",
                @type = "password",
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Password_Empty"))
                    .MinLength(8, this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Password_Incorrect"))
                    .Custom("validatePassword")
		    }
			    ) %>
	    </ControlPart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptPassword" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
        function validatePassword() {
            var value = this; 
            //var ret = /(?=.*\d.+)(?=.*[a-z]+)(?=.*[A-Z]+)(?=.*[-_=+\\|`~!@#$%^&*()\[\]{};:'",./<>?]+).{8,}/.exec(value);
            var ret = <%=this.GetMetadata("Metadata/Settings.Password_ValidationRegex") %>.exec(value);
            if (ret == null || ret.length == 0)
                return '<%= this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Password_UnSafe").SafeJavascriptStringEncode() %>';
            return true;
        }

        function avoidSameUsernamePassword() {
            return <%= Settings.Registration.AvoidSameUsernamePassword.ToString().ToLowerInvariant() %>;
        }
    </script>
    </ui:MinifiedJavascriptControl>
    <div class="button-wrapper">
    <%: Html.Button(this.GetMetadata(".Continue_Button"), new { @type = "submit", @id = "btnSubmit" })%>
    </div>
<%} %>
<script type="text/javascript">
    $(function(){
        $('#formAssociate').initializeForm();
        $(".btnSubmit").click(function(e){
            e.preventDefault();
            var status_form = $('#formAssociate').valid();
            if (!status_form) {
                return;
            }
            $('#formAssociate').submit();
        });
    });
</script>
</asp:Content>

