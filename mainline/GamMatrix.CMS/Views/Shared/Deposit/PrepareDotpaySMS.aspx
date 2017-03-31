<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script type="text/C#" runat="server">
    protected override void OnPreRender(EventArgs e)
    {
        if (Settings.IsUKLicense && !IsAcceptUKTerms())
            Response.Redirect("/Deposit");
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
<%: Html.H1( string.Format( "{0} - {1}", this.GetMetadata(".HEAD_TEXT"), this.Model.GetTitleHtml()) ) %>
<ui:Panel runat="server" ID="pnDeposit">


<% Html.RenderPartial("PaymentMethodDesc", this.Model); %>

<% using (Html.BeginRouteForm("Deposit", new { @action = "ProcessDotpaySMSTransaction", @paymentMethodName = this.Model.UniqueName }, FormMethod.Post, new { @id = "formPrepareDotpaySMSDeposit" }))
   { %>

    <%------------------------------------------
    IovationBlackbox
 -------------------------------------------%>
  <%if (Settings.IovationDeviceTrack_Enabled){ %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
        <%} %>
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
<script language="javascript" type="text/javascript">
//<![CDATA[
    function onGammingAccountChanged(key, data) {
        $('#txtGammingAccountID').val(key);
        //<%-- trigger the validation --%>
        if (InputFields.fields['fldGammingAccount'])
            InputFields.fields['fldGammingAccount'].validator.element($('#txtGammingAccountID'));
    }
//]]>
</script>

<br />
<%------------------------------------------
Captcha
-------------------------------------------%>
<% Html.RenderPartial("/Components/Captcha", this.ViewData.Merge()); %>
<br />

<ui:TabbedContent ID="tabbedDotpaySMS" runat="server">
    <Tabs>

        <%---------------------------------------------------------------
            DotpaySMS
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" 
            Caption="<%$ Metadata:value(/Metadata/PaymentMethod/DotpaySMS.Title) %>" Selected="true">

        <%------------------------
        SMS Code   
        -------------------------%>    
        <ui:InputField ID="fldSMSCode" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".SMSCode_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>

                        
                <%: Html.TextBox("smsCode", "", new 
                { 
                    @maxlength = 10,
                    @dir = "ltr",
                    @validator = ClientValidators.Create().Required(this.GetMetadata(".SMSCode_Empty"))
                } 
                )%>                        
	        </ControlPart>
        </ui:InputField>

        <center>
            <%: Html.Button( this.GetMetadata(".Button_Continue"), new { @type = "submit", @id="btnDepositDotpaySMS", @class="ContinueButton button" })%>
        </center>

</ui:Panel>

    </Tabs>
</ui:TabbedContent>

<% } %>



</ui:Panel>
</div>
<%  Html.RenderPartial("LocalConnection", this.ViewData); %>


<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        $('#formPrepareDotpaySMSDeposit').initializeForm();

        $('#btnDepositDotpaySMS').click(function (e) {
            if (!$('#formPrepareDotpaySMSDeposit').valid()) {
                e.preventDefault();
                return false;
            }
            $(this).toggleLoadingSpin(true);
        });
    });
</script>
<% Html.RenderAction("LimitSetPopup", "Deposit"); %>
<%  Html.RenderPartial("PrepareBodyPlus", this.ViewData ); %>
</asp:Content>

