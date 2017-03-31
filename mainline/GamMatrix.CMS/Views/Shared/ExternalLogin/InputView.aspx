<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<CM.db.cmUser>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GmCore" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <script type="text/C#" runat="server">
        private string GetEmailValidationRegex()
        {
            StringBuilder regex = new StringBuilder();
            regex.Append("/(");
            foreach (string item in Settings.Registration.DisallowedEmailDomain)
            {
                regex.Append("(");
                foreach (char c in item)
                {
                    regex.AppendFormat("\\x{0:x}", (int)c);
                }
                regex.Append(")|");
            }
            if (regex[regex.Length - 1] == '|')
                regex.Remove(regex.Length - 1, 1);
            else
                regex.Append(@"\x40\x40\x40\x40"); // no restriction, then return an impossible regex
            regex.Append(")$/gi");
            return regex.ToString();
        }
        private SelectList GetCurrencyList()
        {
            var list = GamMatrixClient.GetSupportedCurrencies()
                            .FilterForCurrentDomain()
                            .Select(c => new { Key = c.Code, Value = c.GetDisplayName() })
                            .ToList();
            return new SelectList(list
                , "Key"
                , "Value"
                , list.Count > 0 ? list[0].Key : null
                );
        }
    </script>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<%: Html.InformationMessage(this.GetMetadata(".QuickRegister")) %>
<% using (Html.BeginRouteForm("_ExternalLogin", new { @action = "ExternalRegister" }, FormMethod.Post, new { @id = "formExternalLogin" }))
       { %>
    
<%: Html.Hidden("referrerID", this.ViewData["referrerID"])%>
<%------------------------------------------
    Username
    -------------------------------------------%>
    <ui:InputField ID="fldUsername" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Username_Label").SafeHtmlEncode() %></LabelPart>
        <controlpart>
		    <%: Html.TextBox("username", string.Empty, new 
		    {
                @maxlength = Settings.Registration.UsernameMaxLength,
		        @id = "txtUsername",
                @class="textbox",
                @type="text",
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Username_Empty"))
                    .MinLength(4, this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Username_Length"))
                    .Custom("validateUsername")
                    .Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniqueUsername", @message = this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Username_Exist") }))            
		    }
			    ) %>
	    </controlpart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptUsername" AppendToPageEnd="true"
        Enabled="false">
        <script type="text/javascript">
            $(function () {
                $('#txtUsername').keypress(function (e) {
                    if (e.which > 0) {
                        var STR = '\x20\x1F\x7e\x60\x21\x40\x23\x24\x25\x5e\x26\x2a\x28\x29\x5f\x2b\x2d\x3d\x7b\x7d\x7c\x5b\x5d\x5c\x3a\x22\x3b\x27\x3c\x3e\x3f\x2c\x2e\x2f';
                        var c = String.fromCharCode(e.which);
                        if (STR.indexOf(c) >= 0) {
                            e.preventDefault();
                        }
                    }
                });

                $('#txtUsername').change(function (e) {
                    var val = $(this).val();
                    var REGEX = /[\s|\x1F|\x7e|\x60|\x21|\x40|\x23|\x24|\x25|\x5e|\x26|\x2a|\x28|\x29|\x5f|\x2b|\x2d|\x3d|\x7b|\x7d|\x7c|\x5b|\x5d|\x5c|\x3a|\x22|\x3b|\x27|\x3c|\x3e|\x3f|\x2c|\x2e|\x2f]/g;
                    if (val.length > 0) {
                        val = val.replace(REGEX, '');
                        $(this).val(val);
                    }
                });
            });

            function validateUsername() {
                var value = this;
                var ret = /^\w+$/.exec(value);
                if (ret == null || ret.length == 0)
                    return '<%= this.GetMetadata(".Username_Illegal").SafeJavascriptStringEncode() %>';
                return true;
            }
        </script>
    </ui:MinifiedJavascriptControl>
<%------------------------------------------
        Firstname
     -------------------------------------------%>
    <ui:InputField ID="fldFirstName" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata("/QuickRegister/_Step2InputView_ascx.Firstname_Label").SafeHtmlEncode() %></LabelPart>
        <controlpart>
		    <%: Html.TextBox("firstname", this.Model.FirstName, new 
		        {
                    @maxlength = "50",
		            @id = "txtFirstname", 
                    @class="textbox",
                    @type="text",
                    @validator = ClientValidators.Create()
                        .RequiredIf( "isFirstnameRequired", this.GetMetadata("/QuickRegister/_Step2InputView_ascx.Firstname_Empty"))
                        .Custom("validateFirstname")
		        }
			    ) %>
	    </controlpart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptFirstname" AppendToPageEnd="true"
        Enabled="false">
        <script type="text/javascript">
            function isFirstnameRequired() {
                return true;
            }

            function validateFirstname() {
                var value = this;
                var REGEX = /[\x1F|\x7e|\x60|\x21|\x40|\x23|\x24|\x25|\x5e|\x26|\x2a|\x28|\x29|\x5f|\x2b|\x2d|\x3d|\x7b|\x7d|\x7c|\x5b|\x5d|\x5c|\x3a|\x22|\x3b|\x27|\x3c|\x3e|\x3f|\x2c|\x2e|\x2f]/g;
                if( value.length > 0 ){
                    var ret = REGEX.exec(value);
                    if( ret != null && ret.length > 0 )
                        return '<%= this.GetMetadata("/QuickRegister/_Step2InputView_ascx.Firstname_Illegal").SafeJavascriptStringEncode() %>';
        
                    REGEX = /[^x00-xff]/g;
                    value = value.replace(REGEX,"xx");
                    if(value.length < 2)
                        return '<%= this.GetMetadata("/QuickRegister/_Step2InputView_ascx.FirstName_MinLength").SafeJavascriptStringEncode() %>';
                }
                return true;
            }

            $(function () {
                $('#txtFirstname').keypress(function (e) {
                    if (e.which > 0) {
                        var STR = '\x1F\x7e\x60\x21\x40\x23\x24\x25\x5e\x26\x2a\x28\x29\x5f\x2b\x2d\x3d\x7b\x7d\x7c\x5b\x5d\x5c\x3a\x22\x3b\x27\x3c\x3e\x3f\x2c\x2e\x2f';
                        var c = String.fromCharCode(e.which);
                        if (STR.indexOf(c) >= 0) {
                            e.preventDefault();
                        }
                    }
                });

                $('#txtFirstname').change(function (e) {
                    var val = $(this).val();
                    var REGEX = /[\x1F|\x7e|\x60|\x21|\x40|\x23|\x24|\x25|\x5e|\x26|\x2a|\x28|\x29|\x5f|\x2b|\x2d|\x3d|\x7b|\x7d|\x7c|\x5b|\x5d|\x5c|\x3a|\x22|\x3b|\x27|\x3c|\x3e|\x3f|\x2c|\x2e|\x2f]/g;
                    if (val.length > 0) {
                        val = val.replace(REGEX, '');
                        if (val.length > 0)
                            val = val.charAt(0).toUpperCase() + val.substr(1);
                        $(this).val(val);
                    }
                });
            });  
        </script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Surname
     -------------------------------------------%>
    <ui:InputField ID="fldSurname" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata("/QuickRegister/_Step2InputView_ascx.surname").SafeHtmlEncode() %></LabelPart>
        <controlpart>
		    <%: Html.TextBox("surname", this.Model.Surname, new 
		    {
                @maxlength = "50",
                @class="textbox",
                @type="text",
		        @id = "txtSurname", @validator = ClientValidators.Create()
                    .RequiredIf( "isSurnameRequired", this.GetMetadata("/QuickRegister/_Step2InputView_ascx.Surname_Empty"))
                    .Custom("validateSurname")
		    }
			    ) %>
	    </controlpart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptSurname" AppendToPageEnd="true"
        Enabled="false">
        <script type="text/javascript">
            function isSurnameRequired() {
                return true;
            }

            function validateSurname() {
                var value = this;
                var REGEX = /[\x1F|\x7e|\x60|\x21|\x40|\x23|\x24|\x25|\x5e|\x26|\x2a|\x28|\x29|\x5f|\x2b|\x2d|\x3d|\x7b|\x7d|\x7c|\x5b|\x5d|\x5c|\x3a|\x22|\x3b|\x27|\x3c|\x3e|\x3f|\x2c|\x2e|\x2f]/g;
                if( value.length > 0 ){
                    var ret = REGEX.exec(value);
                    if( ret != null && ret.length > 0 )
                        return '<%= this.GetMetadata("/QuickRegister/_Step2InputView_ascx.Surname_Illegal").SafeJavascriptStringEncode() %>';
        
                    REGEX = /[^x00-xff]/g;
                    value = value.replace(REGEX,"xx");
                    if(value.length < 2)
                        return '<%= this.GetMetadata("/QuickRegister/_Step2InputView_ascx.Surname_MinLength").SafeJavascriptStringEncode() %>';
                }
                return true;
            }

            $(function () {
                $('#txtSurname').keypress(function (e) {
                    if (e.which > 0) {
                        var STR = '\x1F\x7e\x60\x21\x40\x23\x24\x25\x5e\x26\x2a\x28\x29\x5f\x2b\x2d\x3d\x7b\x7d\x7c\x5b\x5d\x5c\x3a\x22\x3b\x27\x3c\x3e\x3f\x2c\x2e\x2f';
                        var c = String.fromCharCode(e.which);
                        if (STR.indexOf(c) >= 0) {
                            e.preventDefault();
                        }
                    }
                });

                $('#txtSurname').change(function (e) {
                    var val = $(this).val();
                    var REGEX = /[\x1F|\x7e|\x60|\x21|\x40|\x23|\x24|\x25|\x5e|\x26|\x2a|\x28|\x29|\x5f|\x2b|\x2d|\x3d|\x7b|\x7d|\x7c|\x5b|\x5d|\x5c|\x3a|\x22|\x3b|\x27|\x3c|\x3e|\x3f|\x2c|\x2e|\x2f]/g;
                    if (val.length > 0) {
                        val = val.replace(REGEX, '');
                        if (val.length > 0)
                            val = val.charAt(0).toUpperCase() + val.substr(1);
                        $(this).val(val);
                    }
                });
            });  
        </script>
    </ui:MinifiedJavascriptControl>
<%------------------------------------------
    Currency
     -------------------------------------------%>
    <ui:InputField ID="fldCurrency" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata("/QuickRegister/_Step2InputView_ascx.Currency_Label").SafeHtmlEncode()%></LabelPart>
	    <ControlPart>
            <%: Html.DropDownList( "currency", GetCurrencyList(), new 
            {
                @id = "ddlCurrency",
                @validator = ClientValidators.Create().Required(this.GetMetadata("/QuickRegister/_Step2InputView_ascx.Currency_Empty"))
            })%>
	    </ControlPart>
    </ui:InputField>
<%--------------------------------------------
    Email
    -------------------------------------------%>
    <ui:InputField ID="fldEmail" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Email_Label").SafeHtmlEncode() %></LabelPart>
        <controlpart>
		    <%: Html.TextBox("email", this.Model.Email, new
            {
                @maxlength = "50",
                @id = "txtEmail",
                @class="textbox",
                @type="text",
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Email_Empty"))
                    .Email(this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Email_Incorrect"))
                    .Custom("validateEmailDomain")                
                    .Server(this.Url.RouteUrl("Register", new { @action = "VerifyUniqueEmail", @message = this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Email_Exist") }))
            }
            )%>
	    </controlpart>
    </ui:InputField>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptEmail" AppendToPageEnd="true"
        Enabled="false">
        <script type="text/javascript">
            function validateEmailDomain() {        
                var value = this;
                
                var regex = <%= GetEmailValidationRegex() %>;
                var ret = regex.exec(value);
                if( ret != null && ret.length > 0 )
                    return '<%= this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Email_UnallowedDomain").SafeJavascriptStringEncode() %>';
                
                return true;
            }
        </script>
    </ui:MinifiedJavascriptControl>
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
            if(avoidSameUsernamePassword())
            {
                var _temp = true;
                var $txtUsername = $("#txtUsername");
                if($txtUsername.length>0 && value.toLowerCase()==$txtUsername.val().toLowerCase())
                    _temp = false;
                else
                {
                    var $txtEmail = $("#txtEmail");
                    if($txtEmail.length>0 && value.toLowerCase()==$txtEmail.val().toLowerCase())
                        _temp = false;
                }
                if(!_temp)
                    return '<%= this.GetMetadata("/QuickRegister/_Step1InputView_ascx.Password_SameWithUsername").SafeJavascriptStringEncode() %>';
            }
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

    <%------------------------------------------
        Repeat Password
     -------------------------------------------%>
    <ui:InputField ID="fldRepeatPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	    <LabelPart><%= this.GetMetadata("/QuickRegister/_Step1InputView_ascx.RepeatPassword_Label").SafeHtmlEncode()%></LabelPart>
	    <ControlPart>
		    <%: Html.TextBox("repeatPassword", null, new 
		    {
                @maxlength = 20,
                @id = "txtRepeatPassword",
                @type = "password",
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata("/QuickRegister/_Step1InputView_ascx.RepeatPassword_Empty"))
                    .EqualTo( "#txtPassword", this.GetMetadata("/QuickRegister/_Step1InputView_ascx.RepeatPassword_NotMatch"))
		    }
			    ) %>
	    </ControlPart>
    </ui:InputField>
    <div class="button-wrapper">
        <%: Html.Button("submit", new { @type = "submit", @id = "btnRegisterContinue" })%>
    </div>
<%} %>
<script type="text/javascript">
    $(function(){
        var $form=$('#formExternalLogin');
        $form.initializeForm();
        $form.valid();
        $('#btnRegisterContinue').click(function (e) {
            e.preventDefault();
            var status_form = $form.valid();
            if (!status_form) {
                return;
            }
            var $this = $(this);
            $this.toggleLoadingSpin(true);;
            var options = {
                iframe: false,
                dataType: "html",
                type: 'POST',
                success: function (html) {
                    $this.toggleLoadingSpin(false);
                    $("body").empty().append(html);
                },
                error: function (xhr, textStatus, errorThrown) {
                    $this.toggleLoadingSpin(false);
                    alert(errorThrown);
                }
            };
            $form.ajaxForm(options);
            $form.submit();
        });
    })
</script>
</asp:Content>

