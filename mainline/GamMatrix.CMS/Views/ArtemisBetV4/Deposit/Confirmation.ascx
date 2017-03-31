<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrixAPI.PrepareTransRequest>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PaymentMethod GetPaymentMethod()
    {
        return this.ViewData["paymentMethod"] as PaymentMethod;
    }

    // To be deposited into {0} account
    private string GetCreditMessage()
    {
        return this.GetMetadataEx(".Credit_Account");
    }

    // To be debited from {0}
    private string GetDebitMessage()
    {
        if (GetPaymentMethod().VendorID != VendorID.PaymentTrust)
            return this.GetMetadataEx(".Debit_Account", GetPaymentMethod().GetTitleHtml()).HtmlEncodeSpecialCharactors();

        PayCardRec payCard = GamMatrixClient.GetPayCard(this.Model.Record.DebitPayCardID);
        if (payCard != null)
            return this.GetMetadataEx(".Debit_Card", payCard.DisplayNumber).SafeHtmlEncode();

        return string.Empty;
    }

    private bool IsPayKwik()
    {
        try
        {
            return GetPaymentMethod().VendorID == VendorID.MoneyMatrix && GetPaymentMethod().SubCode == "PayKwik";
        }
        catch (Exception ex)
        {
            return false;
        }
    }

    private string GetConfirmationNote2()
    {
        string text = this.GetMetadata(".Confirmation_Notes_2");
        if (GetPaymentMethod().VendorID == VendorID.Trustly)
            text = this.GetMetadata(".Confirmation_Notes_2_Trustly");
        if (GetPaymentMethod().VendorID == VendorID.TxtNation)
            text = this.GetMetadata(".Confirmation_Notes_2_TXTnation");
        if (GetPaymentMethod().VendorID == VendorID.APX)
            text = this.GetMetadata(".Confirmation_Notes_2_APX");

        if (IsPayKwik())
        {
            text = this.GetMetadata(".Confirmation_Notes_PayKwik");
        }

        if (string.IsNullOrEmpty(text))
            return text;
        text = text.Replace("$AMOUNT$"
            , MoneyHelper.FormatWithCurrencySymbol(this.Model.Record.DebitRealCurrency, this.Model.Record.DebitRealAmount)
            );
        text = text.Replace("$ACCOUNT$"
            , this.GetMetadataEx("/Metadata/GammingAccount/{0}.Display_Name", this.Model.Record.CreditPayItemVendorID.ToString())
            );
        text = text.Replace("$CURRENCY$"
            , this.Model.Record.DebitRealCurrency
            );
        text = text.Replace("$AMOUNT2$"
            , MoneyHelper.FormatWithCurrency(this.Model.Record.DebitRealCurrency, this.Model.Record.DebitRealAmount)
            );
        return text;
    }
    private string GetConfirmationNote()
    {
        string text = "";
        switch (GetPaymentMethod().VendorID)
        {
            case VendorID.Trustly:
                text = this.GetMetadataEx(".Confirmation_NotesNew", this.GetMetadata(".TrustlyConfirmation"));
                break;
            case VendorID.Euteller:
                text = this.GetMetadataEx(".Confirmation_NotesNew", this.GetMetadata(".EutellerConfirmation"));
                break;
            case VendorID.AstroPay:
                text = this.GetMetadata(".Confirmation_Notes_2_Astropay");
                break;
            case VendorID.EnterCash:
                if (Profile.UserCountryID == 79)
                {
                    text = this.GetMetadataEx(".Confirmation_NotesNew", this.GetMetadata(".EntercashConfirmation_Fi"));
                }
                else
                text = this.GetMetadataEx(".Confirmation_NotesNew", this.GetMetadata(".EntercashConfirmation"));
                break;
            default:
                text = this.GetMetadataEx(".Confirmation_NotesNew", "EveryMatrix");
                break;
        }
        return text;
    }
</script>

<%------------------------
    The confirmation table
  ------------------------%>
<table cellpadding="0" cellspacing="0" border="1" rules="all" class="confirmation_table">
    <tr class="confirmation_row_credit">
        <td class="name"><%= GetCreditMessage() %></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency(this.Model.Record.CreditRealCurrency, this.Model.Record.CreditRealAmount)%></td>
    </tr>

    <% if (this.Model.FeeList != null && this.Model.FeeList.Count > 0)
        {
            foreach (var fee in this.Model.FeeList)
            {%>
    <tr class="confirmation_row_fee">
        <td class="name"><%= this.GetMetadata(".Fee").SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency(fee.RealCurrency, fee.RealAmount)%></td>
    </tr>
    <%      }
        } %>


    <tr class="confirmation_row_debit">
        <td class="name"><%= GetDebitMessage() %></td>
        <td class="value"><%= MoneyHelper.FormatWithCurrency( this.Model.Record.DebitRealCurrency, this.Model.Record.DebitRealAmount) %></td>
    </tr>
</table>



<% using (Html.BeginRouteForm("Deposit", new { @action = "Confirm", @paymentMethodName = GetPaymentMethod().UniqueName, @sid = this.Model.Record.Sid, @_sid = Profile.SessionID }, FormMethod.Post, new { @method = "post", @target = "_blank", @id = "pnComfirmForm" }))
   { %>
<center>
  <% if (GetPaymentMethod().VendorID == VendorID.GCE)
     { %>
  <br />
  <%: Html.InformationMessage(this.GetMetadata(".Confirmation_Notes_GCE"), false, new { @id = "confirmationNote" })%>
  <% } %>
  <% else if (GetPaymentMethod().VendorID == VendorID.TxtNation)
     { %>
  <br />
   <%: Html.InformationMessage(GetConfirmationNote2(), false, new { @id = "confirmationNote2" })%>
  <% } %>
  <% else if (GetPaymentMethod().VendorID == VendorID.MoneyMatrix && GetPaymentMethod().SubCode == "OtoPay")
     { %>
  <br />
   <%: Html.InformationMessage(GetConfirmationNote2(), false, new { @id = "confirmationNote2" })%>
  <% } %>
    
   <% else if (GetPaymentMethod().VendorID == VendorID.MoneyMatrix)
  { %>
    <br />
    <%: Html.InformationMessage(this.GetMetadata(".Confirmation_Notes_MoneyMatrix"), false, new { @id = "confirmationNote" })%>
    <br />
    <%: Html.InformationMessage(GetConfirmationNote2(), false, new { @id = "confirmationNote2" })%>
  <% } %>
  
    <% else if (GetPaymentMethod().UniqueName == "Epro")
     { %>
        <br />
        <%: Html.InformationMessage(this.GetMetadata(".Confirmation_Notes_Epro"), false, new { @id = "confirmationNote" })%>
        <br />
        <%: Html.InformationMessage(GetConfirmationNote2(), false, new { @id = "confirmationNote2" })%>
  <% } %>
    <%else if(GetPaymentMethod().VendorID == VendorID.AstroPay) { %>
     <%: Html.InformationMessage(GetConfirmationNote(), false, new { @id = "confirmationNote" })%>
    <%} %>
  <% else if (GetPaymentMethod().VendorID != VendorID.TLNakit && GetPaymentMethod().VendorID != VendorID.APX)
     { %>
  <br />
  <%: Html.InformationMessage(GetConfirmationNote(), false, new { @id = "confirmationNote" })%>
  <br />
  <%: Html.InformationMessage(GetConfirmationNote2(), false, new { @id = "confirmationNote2" })%>
  <% } %>
  <br />
  <div>
    <%: Html.Button(this.GetMetadata(".Button_Back"), new { @onclick = "returnPreviousDepositStep(); return false;", @type="button", @class="BackButton button" })%>
    <%: Html.Button(this.GetMetadata(".Button_Confirm"), new { @type="submit", @onclick="__onBtnDepositConfirmClicked();", @class="ConfirmButton button" })%>
  </div>
</center>
<% } %>


<div id="deposit-block-dialog" style="display: none">
    <div class="content-wrapper">
        <div class="DialogHeader">
            <span class="DialogIcon">ArtemisBet</span>
            <h3 class="DialogTitle"><%= this.GetMetadata(".Popup_Title") %></h3>
            <p class="DialogInfo"><%= this.GetMetadata(".LoginDialogInfo") %></p>
        </div>
        <h3><%= this.GetMetadata(".Block_Dialog_Title").SafeHtmlEncode() %></h3>
        <ul class="deposit-block-dialog-operations">
            <li>
                <strong><%= this.GetMetadata(".Success").SafeHtmlEncode() %></strong> : 
           
                <a href="<%= this.Url.RouteUrl("Deposit", new { @action = "Receipt", @sid = this.Model.Record.Sid, @paymentMethodName = GetPaymentMethod().UniqueName }).SafeHtmlEncode() %>" target="_top"><%= this.GetMetadata(".Success_Link_Text").SafeHtmlEncode()%></a>
            </li>
            <li>
                <strong><%= this.GetMetadata(".Failure").SafeHtmlEncode()%></strong> : 
           
                <a href="mailto:<%= this.GetMetadata("/Metadata/Settings.Email_SupportAddress").SafeHtmlEncode()%>" target="_blank"><%= this.GetMetadata(".Failure_Link_Text").SafeHtmlEncode()%></a>
            </li>
        </ul>
        <div class="RegisterSupport">
            <%=this.GetMetadata(".RegisterSupportGirl") %>
            <p class="RegisterSupportText"><%= this.GetMetadata(".RegisterSupportText") %></p>
        </div>
    </div>
</div>

<ui:MinifiedJavascriptControl runat="server">
    <script type="text/javascript">
        jQuery('body').addClass('DepositPage');
        jQuery('.inner').addClass('ProfileContent DepositContent');
        jQuery('.MainProfile').addClass('MainDeposit');
        jQuery('.sidemenu li').addClass('PMenuItem');
        jQuery('.sidemenu li span').addClass('PMenuLinkContainer');
        jQuery('.sidemenu li span a').addClass('ProfileMenuLinks');

        setTimeout(function () {
            jQuery('.ProfileContent').prepend(jQuery('#ProfileTitle'));
        }, 1);

        //<![CDATA[
        function __onBtnDepositConfirmClicked() {
            $('#deposit-block-dialog').modalex(600, 450, false);
            $('#deposit-block-dialog').parents("#simplemodal-container").addClass("deposit-block-dialog-container").addClass('forgotpassword-popup').addClass('register-popup').addClass('register-popup-Container').css({ 'padding-top': '5em' });
            jQuery('body').removeClass('DepositPage');
        }

        self.redirectToReceiptPage = function (url) {
            if (url == null || url.trim() == '')
                url = '<%= this.Url.RouteUrl("Deposit", new { @action = "Receipt", @sid = this.Model.Record.Sid, @paymentMethodName = GetPaymentMethod().UniqueName }).SafeJavascriptStringEncode() %>';
    window.location = url;
    return true;
};
//]]>
</script>
</ui:MinifiedJavascriptControl>
