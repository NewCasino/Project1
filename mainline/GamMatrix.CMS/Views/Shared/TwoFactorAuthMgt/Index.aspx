<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <style type="text/css">
        .button{margin:20px 0;}
    </style>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<%: Html.H2("Generate and send second factor auth code")%>

<% using (Html.BeginRouteForm("Login", new { @action = "GenerateAndSendSecondFactorBackupCode" }, FormMethod.Post, new { @id = "formGenerateAndSendSecondFactorBackupCode" }))
    { %>
<ui:InputField ID="fldUsername" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart>Username: </LabelPart>
    <ControlPart>
        <%: Html.TextBox( "username", string.Empty, new 
        {
            @maxlength = "100",
            @id = "txtUsername",
            @validator = ClientValidators.Create()
                .Required("please enter username")
                .MinLength( 2, "please enter username")
        }
            ) %>
    </ControlPart>
</ui:InputField>

<%: Html.Button("Resend authentication code Email", new { @type= "submit", @id = "btnGenerateAndSendSecondFactorBackupCode"})%>
<%: Html.Button("Reset Login preference", new { @type= "submit", @id = "btnResetLoginPreference"})%>
<%: Html.Button("Activate 2 step flow with GA for Smartphone", new { @type= "submit", @id = "btnSmartphone"})%>
<%: Html.Button("Activate 2 step flow with email codes", new { @type= "submit", @id = "btnEmailCodes"})%>    
<% } %>


<script type="text/javascript">
    $(document).ready(function () {
        $form = $('#formGenerateAndSendSecondFactorBackupCode');
        $form.initializeForm();

        $('#btnGenerateAndSendSecondFactorBackupCode').click(function (e) {
            e.preventDefault();

            if (!$form.valid())
                return;

            $(this).toggleLoadingSpin(true);
            var options = {
                dataType: "json",
                type: 'POST',
                success: function (data) {
                    $('#btnGenerateAndSendSecondFactorBackupCode').toggleLoadingSpin(false);
                    if (data && !data.success) {
                        alert(data.error);
                    } else {
                        alert('success');
                    }
                },
                error: function (xhr, textStatus, errorThrown) {
                    alert(errorThrown);
                    $('#btnGenerateAndSendSecondFactorBackupCode').toggleLoadingSpin(false);
                }
            };
            $form.prop('action', '<%= this.Url.RouteUrlEx("Login", new { @action="GenerateAndSendSecondFactorBackupCode"}).SafeJavascriptStringEncode()%>');
            $form.ajaxForm(options);
            $form.submit();
        });


        $('#btnResetLoginPreference').click(function (e) {
            e.preventDefault();

            if (!$form.valid())
                return;

            $(this).toggleLoadingSpin(true);
            var options = {
                dataType: "json",
                type: 'POST',
                success: function (data) {
                    $('#btnResetLoginPreference').toggleLoadingSpin(false);
                    if (data && !data.success) {
                        alert(data.error);
                    } else {
                        alert('success');
                    }
                },
                error: function (xhr, textStatus, errorThrown) {
                    alert(errorThrown);
                    $('#btnResetLoginPreference').toggleLoadingSpin(false);
                }
            };
            $form.prop('action', '<%= this.Url.RouteUrlEx("Login", new { @action="ResetSendSecondAuth"}).SafeJavascriptStringEncode()%>');
            $form.ajaxForm(options);
            $form.submit();
        });

        $('#btnSmartphone').click(function (e) {
            e.preventDefault();

            if (!$form.valid())
                return;

            $(this).toggleLoadingSpin(true);
            var options = {
                dataType: "json",
                type: 'POST',
                data: {secondFactorType: <%=(int)TwoFactorAuth.SecondFactorAuthType.GoogleAuthenticator %>},
                success: function (data) {
                    $('#btnSmartphone').toggleLoadingSpin(false);
                    if (data && !data.success) {
                        alert(data.error);
                    } else {
                        alert('success');
                    }
                },
                error: function (xhr, textStatus, errorThrown) {
                    alert(errorThrown);
                    $('#btnSmartphone').toggleLoadingSpin(false);
                }
            };
            $form.prop('action', '<%= this.Url.RouteUrlEx("Login", new { @action="SetSecondFactorType"}).SafeJavascriptStringEncode()%>');
            $form.ajaxForm(options);
            $form.submit();
        });

        $('#btnEmailCodes').click(function (e) {
            e.preventDefault();

            if (!$form.valid())
                return;

            $(this).toggleLoadingSpin(true);
            var options = {
                dataType: "json",
                data: {secondFactorType: <%=(int)TwoFactorAuth.SecondFactorAuthType.GeneralAuthCode %>},
                type: 'POST',
                success: function (data) {
                    $('#btnEmailCodes').toggleLoadingSpin(false);
                    if (data && !data.success) {
                        alert(data.error);
                    } else {
                        alert('success');
                    }
                },
                error: function (xhr, textStatus, errorThrown) {
                    alert(errorThrown);
                    $('#btnEmailCodes').toggleLoadingSpin(false);
                }
            };
            $form.prop('action', '<%= this.Url.RouteUrlEx("Login", new { @action="SetSecondFactorType"}).SafeJavascriptStringEncode()%>');
            $form.ajaxForm(options);
            $form.submit();
        });
    });
</script>
</asp:Content>

