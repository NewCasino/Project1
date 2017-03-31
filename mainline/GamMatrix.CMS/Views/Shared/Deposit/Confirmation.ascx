<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrixAPI.PrepareTransRequest>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private bool SafeParseBoolString(string text, bool defValue)
    {
        if (string.IsNullOrWhiteSpace(text))
            return defValue;

        text = text.Trim();

        if (Regex.IsMatch(text, @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            return true;

        if (Regex.IsMatch(text, @"(NO)|(OFF)|(FALSE)|(\0)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            return false;

        return defValue;
    }
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
        PayCardRec payCard = GamMatrixClient.GetPayCard(this.Model.Record.DebitPayCardID);

        if (GetPaymentMethod().VendorID == VendorID.MoneyMatrix && GetPaymentMethod().UniqueName == "MoneyMatrix")
            return this.GetMetadataEx(".Debit_Card",   payCard.DisplayName).SafeHtmlEncode();

        if (GetPaymentMethod().VendorID != VendorID.PaymentTrust)
            return this.GetMetadataEx(".Debit_Account", GetPaymentMethod().GetTitleHtml()).HtmlEncodeSpecialCharactors();

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

    private bool IsOtoPay()
    {
        try
        {
            return GetPaymentMethod().VendorID == VendorID.MoneyMatrix && GetPaymentMethod().SubCode == "OtoPay";
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
        if (GetPaymentMethod().VendorID == VendorID.MoneyMatrix)
            text = this.GetMetadata(".Confirmation_Notes_MoneyMatrix_Convert");

        if (string.IsNullOrEmpty(text))
            return text;

        if (IsPayKwik())
        {
            text = this.GetMetadata(".Confirmation_Notes_PayKwik");
        }

        if (IsOtoPay())
        {
            text = this.GetMetadata(".Confirmation_Notes_OtoPay");
        }
        
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

        text = MoneyHelper.FormatCurrencySymbol(text);
        
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

    private bool IsPaymentPopupEnable()
    {
        var result = false;

        if (SafeParseBoolString(Metadata.Get("/Metadata/Settings/Deposit.Comfirmation_EnablePopup"), true))
        {
            var enabledVendors = Metadata.Get("/Metadata/Settings/Deposit.Comfirmation_EnabledPopup_Vendors").Split(new []{','})
                .Select(x => x.Trim());

            var paymentMethod = GetPaymentMethod();

            result = enabledVendors.Any(x => x == paymentMethod.UniqueName || x == paymentMethod.VendorID.ToString());
        }
        
        return result;
    }
</script>
<%------------------------
    The confirmation table
  ------------------------%>

<table cellpadding="0" cellspacing="0" border="1" rules="all" class="confirmation_table">
    <tr class="confirmation_row_credit">
        <td class="name"><%= GetCreditMessage() %></td>
        <td class="value"><%= MoneyHelper.FormatCurrencySymbol(MoneyHelper.FormatWithCurrency(this.Model.Record.CreditRealCurrency, this.Model.Record.CreditRealAmount))%></td>
    </tr>
    <% if (this.Model.FeeList != null && this.Model.FeeList.Count > 0)
       {
           foreach (var fee in this.Model.FeeList)
           {%>
    <tr class="confirmation_row_fee">
        <td class="name"><%= this.GetMetadata(".Fee").SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatCurrencySymbol(MoneyHelper.FormatWithCurrency(fee.RealCurrency, fee.RealAmount))%></td>
    </tr>
    <%      }
       } %>
    <tr class="confirmation_row_debit">
        <td class="name"><%= GetDebitMessage() %></td>
        <td class="value"><%= MoneyHelper.FormatCurrencySymbol(MoneyHelper.FormatWithCurrency( this.Model.Record.DebitRealCurrency, this.Model.Record.DebitRealAmount)) %></td>
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
    <h3><%=string.Equals(GetPaymentMethod().UniqueName,"Trustly",StringComparison.InvariantCultureIgnoreCase) ?  this.GetMetadata(".Block_Dialog_Popup_Title").SafeHtmlEncode() : this.GetMetadata(".Block_Dialog_Title").SafeHtmlEncode() %></h3>
    <hr />
    <ul class="deposit-block-dialog-operations">
        <li><strong><%= this.GetMetadata(".Success").SafeHtmlEncode() %></strong> : <a href="<%= this.Url.RouteUrl("Deposit", new { @action = "Receipt", @sid = this.Model.Record.Sid, @paymentMethodName = GetPaymentMethod().UniqueName }).SafeHtmlEncode() %>" target="_top"><%= this.GetMetadata(".Success_Link_Text").SafeHtmlEncode()%></a> </li>
        <li><strong><%= this.GetMetadata(".Failure").SafeHtmlEncode()%></strong> : <a href="mailto:<%= this.GetMetadata("/Metadata/Settings.Email_SupportAddress").SafeHtmlEncode()%>" target="_blank"><%= this.GetMetadata(".Failure_Link_Text").SafeHtmlEncode()%></a> </li>
    </ul>
</div>
    <style>
.ConfirmationBox {display: none;position: fixed;z-index: 999999;left: 0;top: 0;width: 100%;height: 100%;background: rgba(0,0,0,.7);}
.ConfirmationFrame,  .ConfirmationFrameData {height: 100%;position: relative;margin: 0 auto;}
.ConfirmationIframe {margin: 5%;height: 85%;width: 90%;height: 90%;background:#fff;}
.ConfirmationClose {display: block;background: #ffffff;background: url(data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiA/Pgo8c3ZnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgdmlld0JveD0iMCAwIDEgMSIgcHJlc2VydmVBc3BlY3RSYXRpbz0ibm9uZSI+CiAgPGxpbmVhckdyYWRpZW50IGlkPSJncmFkLXVjZ2ctZ2VuZXJhdGVkIiBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSIgeDE9IjAlIiB5MT0iMCUiIHgyPSIwJSIgeTI9IjEwMCUiPgogICAgPHN0b3Agb2Zmc2V0PSIwJSIgc3RvcC1jb2xvcj0iI2ZmZmZmZiIgc3RvcC1vcGFjaXR5PSIxIi8+CiAgICA8c3RvcCBvZmZzZXQ9IjEwMCUiIHN0b3AtY29sb3I9IiNjZWNlY2UiIHN0b3Atb3BhY2l0eT0iMSIvPgogIDwvbGluZWFyR3JhZGllbnQ+CiAgPHJlY3QgeD0iMCIgeT0iMCIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0idXJsKCNncmFkLXVjZ2ctZ2VuZXJhdGVkKSIgLz4KPC9zdmc+);background: -moz-linear-gradient(top, #ffffff 0%, #cecece 100%);background: -webkit-gradient(linear, left top, left bottom, color-stop(0%, #ffffff), color-stop(100%, #cecece));background: -webkit-linear-gradient(top, #ffffff 0%, #cecece 100%);background: -o-linear-gradient(top, #ffffff 0%, #cecece 100%);background: -ms-linear-gradient(top, #ffffff 0%, #cecece 100%);background: linear-gradient(to bottom, #ffffff 0%, #cecece 100%);filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#ffffff', endColorstr='#cecece', GradientType=0 );font-weight: 700;height: 30px;width: 30px;position: absolute;top: 10px;right: 10px;border-radius: 50%;text-align: center;line-height: 30px;font-size: 16px;z-index: 998;}
.ConfirmationClose:hover {background: #ccc;}
.ConfirmationClose .CloseText {text-indent: 0;color: #333;}
    </style>
<div class="ConfirmationBox simplemodal-container deposit-confirm-container">
    <div class="ConfirmationFrame simplemodal-wrap">
        <div class="ConfirmationFrameData simplemodal-data">
            <iframe src="about:blank" name="ConfirmationIframe"  marginwidth="0"  marginheight="0" align="middle" scrolling="auto" frameborder="0" hspace="0" vspace="0" class="ConfirmationIframe" id="ConfirmationIframe" title="Confirmation Iframe" allowtransparency="true" border="0"></iframe>
        </div>
        <a href="javascript:void(0);" class="ConfirmationClose ClosePopup"><span class="CloseText"><%=this.GetMetadata(".Close_Text").DefaultIfNullOrEmpty("X") %></span></a>
    </div>
</div>
<script type="text/javascript">
    var paymentPopupEnable = <%= IsPaymentPopupEnable() ? "true" : "false" %>;
    
    if (paymentPopupEnable) {
        $("#pnComfirmForm").attr("target", "ConfirmationIframe");
        $(".ConfirmationFrame").width($(".left-pane").width() + $(".content-wrapper").width());
    }
    var hidePopupFrame = function () {
        $(".ConfirmationBox.simplemodal-container").hide();
    };
    $(".ConfirmationClose").click(function(){hidePopupFrame();});
    //<![CDATA[
    function __onBtnDepositConfirmClicked() {
        <%if(Settings.IovationDeviceTrack_Enabled){%>
        var iovationBox = $("input[name='iovationBlackBox']").clone();
        iovationBox.removeAttr('id');
        $("#pnComfirmForm").append(iovationBox);
        <%}%>
        $('#deposit-block-dialog').modalex(400, 150, false);
        $('#deposit-block-dialog').parents("#simplemodal-container").addClass("deposit-block-dialog-container");
        if (paymentPopupEnable) {
            $(".ConfirmationBox.simplemodal-container").appendTo("body").show();
            //$(".ConfirmationBox.simplemodal-container").click(function () {
            //    hidePopupFrame();
            //});
        }
    } 
    self.redirectToReceiptPage = function (url) {
        if(url==null || url.trim() == '')
            url = '<%= this.Url.RouteUrl("Deposit", new { @action = "Receipt", @sid = this.Model.Record.Sid, @paymentMethodName = GetPaymentMethod().UniqueName }).SafeJavascriptStringEncode() %>';
        window.location = url;
        return true;
    };
    //]]>
</script>
