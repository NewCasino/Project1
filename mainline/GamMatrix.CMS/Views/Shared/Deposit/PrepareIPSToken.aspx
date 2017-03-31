<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script language="C#" type="text/C#" runat="server">    
    private PayCardInfoRec GetDummyPayCard()
    {
        PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.IPSToken)
            .Where(p => p.IsDummy)
            .FirstOrDefault();
        if (payCard == null)
            throw new Exception("IPS is not configrured in GmCore correctly, missing dummy pay card.");
        return payCard;
    }
    
    protected override void OnPreRender(EventArgs e)
    {
        if (Settings.IsUKLicense && !IsAcceptUKTerms())
            Response.Redirect("/Deposit");
        string title = this.GetMetadata(".Title");
        if (title != null)
            this.Title = title.Replace("$PAYMENTMETHOD$", this.Model.GetTitleHtml());

        string desc = this.GetMetadata(".Description");
        if (desc != null)
            this.MetaDescription = desc.Replace("$PAYMENTMETHOD$", this.Model.GetTitleHtml());


        string keywords = this.GetMetadata(".Keywords");
        if (keywords != null)
            this.MetaDescription = keywords.Replace("$PAYMENTMETHOD$", this.Model.GetTitleHtml());
        base.OnPreRender(e);
    }
    protected bool IsAcceptUKTerms()
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(Profile.UserID);
        return user.IsTCAcceptRequired.HasFlag(TermsConditionsChange.UKLicense);
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="deposit-wrapper" class="content-wrapper">
<ui:Header ID="Header1" runat="server" HeadLevel="h1">
    <%= this.GetMetadata(".HEAD_TEXT").SafeHtmlEncode() %>
    -
    <%= this.Model.GetTitleHtml().HtmlEncodeSpecialCharactors() %>
</ui:Header>

<ui:Panel runat="server" ID="pnDeposit">
<% Html.RenderPartial("PaymentMethodDesc", this.Model); %>

<div class="deposit_steps">
<div id="prepare_step">
<% using (Html.BeginRouteForm("Deposit"
       , new { @action = "ProcessIPSTokenTransaction", @paymentMethodName = this.Model.UniqueName }
       , FormMethod.Post
       , new { @id = "formIPSPayCard", @target = "_self" }
       ))
   { %>
    <%------------------------------------------
    IovationBlackbox
 -------------------------------------------%>
  <%if (Settings.IovationDeviceTrack_Enabled){ %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
        <%} %>

<%: Html.Hidden("payCardID", GetDummyPayCard().ID.ToString(), new 
                    { 
                        @id = "hPayCardID",
                    }) %>
   
<%------------------------------------------
    Gamming Accounts
 -------------------------------------------%>
<ui:InputField ID="fldGammingAccount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".GammingAccount_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
        <% Html.RenderPartial("/Components/GammingAccountSelector", this.ViewData.Merge(new
           {
               @AutoSelect = true,
               @TableID = "table_gamming_account",
               @ClientOnChangeFunction = "onGammingAccountChanged",               
           }) ); %>
        <%: Html.Hidden("gammingAccountID", "", new { @id = "txtGammingAccountID", @validator = ClientValidators.Create().Required(this.GetMetadata(".GammingAccount_Empty")) })%>
</ControlPart>
</ui:InputField>
<script type="text/javascript">
//<![CDATA[
function onGammingAccountChanged(key, data) {
    $('#txtGammingAccountID').val(key);
    //<%-- trigger the validation --%>
    if( InputFields.fields['fldGammingAccount'] )
        InputFields.fields['fldGammingAccount'].validator.element($('#txtGammingAccountID'));
}
//]]>
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>
        <%---------------------------------------------------------------
            IPSToken
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/IPSToken.Title) %>" Selected="true">
            <form id="formIPSPayCard" action="<%= this.Url.RouteUrl("Deposit", new { @action = "SaveIPSToken", @vendorID=this.Model.VendorID }).SafeHtmlEncode() %>" method="post" enctype="application/x-www-form-urlencoded">

                <%: Html.Hidden( "sid", "") %>

                <%: Html.WarningMessage(this.GetMetadata(".Warning_Message"))  %>

                <%------------------------
                    Token
                -------------------------%>    
                <ui:InputField ID="fldUkashNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".Token_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <%: Html.TextBox("token", "", new 
                        { 
                            @id = "txtIPSToken",
                            @maxlength = 50,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".Token_Empty"))
                        } 
                        )%>
                </ControlPart>
                </ui:InputField>

                <%------------------------
                    Check Digits
                -------------------------%>    
                <ui:InputField ID="fldIPSCheckDigit" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".CheckDigit_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <%: Html.TextBox("checkDigit", "", new 
                        {
                            @maxlength = 10,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".CheckDigit_Empty"))
                        } 
                        )%>
                </ControlPart>
                </ui:InputField>

                

                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithIPSPayCard", @class="ContinueButton button" })%>
                </center>
            </form>
        </ui:Panel>
    </Tabs>
</ui:TabbedContent>


<% } %>


</div>


<div id="error_step" style="display:none">
    <%: Html.ErrorMessage("", false, new { @id = "msgIPSTokenError" })%>
    <br />
    <center>
        <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @id = "btnIPSTokenErrorBack", @class="BackButton button" })%>
    </center>

</div>

</div>

</ui:Panel>

</div>

<script type="text/javascript">
//<![CDATA[
    function showDepositError(errorText) {
        try {
            if (self.parent !== null && self.parent != self) {
                var targetOrigin = '<%=this.GetMetadata("/Deposit/_Prepare_aspx.TargetOriginForPostMessage").SafeJavascriptStringEncode().DefaultIfNullOrWhiteSpace("") %>';
                if (targetOrigin.trim() == '') {
                    targetOrigin = top.window.location.href;
                }
                window.top.postMessage('{"user_id":<%=CM.State.CustomProfile.Current.UserID %>, "message_type": "deposit_result", "success": false, "message": "' + errorText + '"}', targetOrigin);
            }
        } catch (e) { console.log(e); }
        
        $('#error_step div.message_Text').text(errorText);
        $('div.deposit_steps > div').hide();
        $('#error_step').show();
    }

    $(function () {

        $('#formIPSPayCard').initializeForm();

        $('#formIPSPayCard input').allowNumberOnly();

        $('#btnDepositWithIPSPayCard').click(function (e) {
            e.preventDefault();
            if (!$('#formIPSPayCard').valid())
                return false;

            $(this).toggleLoadingSpin(true);

            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    if (!json.success) {
                        $('#btnDepositWithIPSPayCard').toggleLoadingSpin(false);
                        if (json.error != null)
                            showDepositError(json.error);
                        else
                            showDepositError('<%= this.GetMetadata(".Message_DepositFailed").SafeJavascriptStringEncode() %>');
                        return;
                    }

                    window.location = json.receiptUrl;
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnDepositWithIPSPayCard').toggleLoadingSpin(false);
                    showDepositError(errorThrown);
                }
            };
            $('#formIPSPayCard').ajaxForm(options);
            $('#formIPSPayCard').submit();
        });

        $('#btnIPSTokenErrorBack').click(function () {
            $('div.deposit_steps > div').hide();
            $('#prepare_step').show();
        });
    });
//]]>
</script>
    
<% Html.RenderAction("LimitSetPopup", "Deposit"); %>
<%  Html.RenderPartial("PrepareBodyPlus", this.ViewData ); %>
</asp:Content>
