<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrixAPI.PrepareTransRequest>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private   bool SafeParseBoolString(string text, bool defValue)
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

    private string GetDebitMessage()
    {
        if (GetPaymentMethod().VendorID == VendorID.MoneyMatrix)
            return string.Format(this.GetMetadata(".DebitAccount_MoneyMatrix"));

        return string.Format(this.GetMetadata(".DebitAccount"),
            this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", this.Model.Record.DebitPayItemVendorID)));
    }

    private string GetCreditMessage()
    {
        PayCardRec payCard = GamMatrixClient.GetPayCard(this.Model.Record.CreditPayCardID);

        string creditMsgName = "";
        if (GetPaymentMethod().VendorID != VendorID.Bank)
        {
            if (GetPaymentMethod().VendorID == VendorID.Ukash)
            {
                creditMsgName = string.Format(this.GetMetadata(".CreditCard")
                    , GetPaymentMethod().GetTitleHtml()
                    );
            }
            else if (GetPaymentMethod().VendorID == VendorID.APX)
            {
                creditMsgName = string.Format(this.GetMetadata(".CreditCard")
                    , string.Format("{0}, {1}", this.GetMetadata(".BankAccount"), payCard.DisplayName)
                    );
            }
            else if (GetPaymentMethod().VendorID == VendorID.Nets)
            {
                creditMsgName = string.Format(this.GetMetadata(".CreditCard"), this.GetMetadata(".YourBankAccount"));
            }
            else if(GetPaymentMethod().VendorID == VendorID.MoneyMatrix && GetPaymentMethod().UniqueName == "MoneyMatrix")
            {
                creditMsgName = string.Format(this.GetMetadata(".CreditCard"), string.Format("the card {0}", payCard.DisplayName));
            }
            else if(GetPaymentMethod().VendorID == VendorID.MoneyMatrix)
            {
                creditMsgName = string.Format(this.GetMetadata(".CreditCard"), GetPaymentMethod().GetTitleHtml());
            }
            else
            {
                creditMsgName = string.Format(this.GetMetadata(".CreditCard")
                    , string.Format("{0}, {1}", GetPaymentMethod().GetTitleHtml(), payCard.DisplayName)
                    );
            }
        }
        else
        {
            creditMsgName = string.Format(this.GetMetadata(".CreditCard")
                    , string.Format("{0}, {1}", payCard.BankName, payCard.DisplayName)
                    );
        }
        return string.IsNullOrEmpty(creditMsgName) ? "" : creditMsgName.Replace(", Dummy card", "");
    }
</script>

<%------------------------
    The confirmation table
  ------------------------%>
<table cellpadding="0" cellspacing="0" border="1" rules="all" class="confirmation_table">

    <tr class="confirmation_row_debit">
        <td class="name"><%= GetDebitMessage().SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatCurrencySymbol(MoneyHelper.FormatWithCurrency( this.Model.Record.DebitCurrency
                              , this.Model.Record.DebitAmount)) %></td>
    </tr>

    <% if (this.Model.FeeList != null && this.Model.FeeList.Count > 0)
       {
           foreach (TransFeeRec fee in this.Model.FeeList)
           {%>
    <tr class="confirmation_row_fee">
        <td class="name"><%= this.GetMetadata(".Fee").SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatCurrencySymbol(MoneyHelper.FormatWithCurrency(fee.RealCurrency
                              , fee.RealAmount)) %></td>
    </tr>
    <%     }
       }%>

    <tr class="confirmation_row_credit">
        <td class="name"><%= GetCreditMessage().SafeHtmlEncode()%></td>
        <td class="value"><%= MoneyHelper.FormatCurrencySymbol(MoneyHelper.FormatWithCurrency( this.Model.Record.CreditRealCurrency
                              , this.Model.Record.CreditRealAmount)) %></td>
    </tr>

</table>

<% using (Html.BeginRouteForm("Withdraw", new { @action = "Confirm", @paymentMethodName = GetPaymentMethod().UniqueName, @sid = this.Model.Record.Sid }, FormMethod.Post, new { @method = "post",  @target = "_blank", @Id="pnWidthDrawComfirmation" }))
   { %>

<center>
    <br />
    <% Html.RenderPartial("/Components/ForfeitBonusWarning", this.ViewData.Merge(new { @VendorID = this.Model.Record.DebitPayItemVendorID, @DebitAmount = this.Model.Record.DebitRealAmount })); %>

    <br />
    <%: Html.Button(this.GetMetadata(".Button_Back"), new { @onclick = "returnPreviousWithdrawStep(); return false;", @type="button", @class="BackButton button" })%>
    <%: Html.Button(this.GetMetadata(".Button_Confirm"), new { @type = "submit", @onclick = "$(this).toggleLoadingSpin(true);", @class="ConfirmButton button" })%>  
</center>

<% } %>
<div class="ConfirmationBox simplemodal-container widthdraw-confirm-container" style="display: none; position: fixed; z-index: 999999; left: 0; top: 0; width: 100%; height: 100%; background: rgba(0,0,0,.7);">
    <div class="ConfirmationFrame simplemodal-wrap" style="height: 100%;">
        <div class="ConfirmationFrameData simplemodal-data" style="height: 100%;">
            <iframe src="about:blank" name="ConfirmationIframe" style="margin-top: 5%; height: 85%;" width="90%" marginwidth="0" height="90%" marginheight="0" align="middle" scrolling="auto" frameborder="0" hspace="0" vspace="0" class="ConfirmationIframe" id="ConfirmationIframe" title="Confirmation Iframe" allowtransparency="true" border="0"></iframe>
        </div>
    </div>
    <style>.ConfirmationClose {  display: block;  background: #ffffff;background: url(data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiA/Pgo8c3ZnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgdmlld0JveD0iMCAwIDEgMSIgcHJlc2VydmVBc3BlY3RSYXRpbz0ibm9uZSI+CiAgPGxpbmVhckdyYWRpZW50IGlkPSJncmFkLXVjZ2ctZ2VuZXJhdGVkIiBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSIgeDE9IjAlIiB5MT0iMCUiIHgyPSIwJSIgeTI9IjEwMCUiPgogICAgPHN0b3Agb2Zmc2V0PSIwJSIgc3RvcC1jb2xvcj0iI2ZmZmZmZiIgc3RvcC1vcGFjaXR5PSIxIi8+CiAgICA8c3RvcCBvZmZzZXQ9IjEwMCUiIHN0b3AtY29sb3I9IiNjZWNlY2UiIHN0b3Atb3BhY2l0eT0iMSIvPgogIDwvbGluZWFyR3JhZGllbnQ+CiAgPHJlY3QgeD0iMCIgeT0iMCIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0idXJsKCNncmFkLXVjZ2ctZ2VuZXJhdGVkKSIgLz4KPC9zdmc+);
background: -moz-linear-gradient(top, #ffffff 0%, #cecece 100%); background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#ffffff), color-stop(100%,#cecece));background: -webkit-linear-gradient(top, #ffffff 0%,#cecece 100%);background: -o-linear-gradient(top, #ffffff 0%,#cecece 100%);background: -ms-linear-gradient(top, #ffffff 0%,#cecece 100%);background: linear-gradient(to bottom, #ffffff 0%,#cecece 100%);filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#ffffff', endColorstr='#cecece',GradientType=0 );font-weight:700;height: 30px;  width: 30px;  position: absolute;  top: 10px;  right: 10px;  border-radius: 50%;  text-align: center;  line-height: 30px;  font-size: 16px;z-index:998;}.ConfirmationClose:hover {background:#ccc;}</style>
    <a href="javascript:void(0);" class="ConfirmationClose ClosePopup"><span class="CloseText"><%=this.GetMetadata(".Close_Text").DefaultIfNullOrEmpty("X") %></span></a>
</div>
<script type="text/javascript">    
    var paymentPopupEnable  = <%= SafeParseBoolString(Metadata.Get("/Metadata/Settings/Withdraw.Comfirmation_EnablePopup"), true)  ? ((Metadata.Get("/Metadata/Settings/Withdraw.Comfirmation_EnabledPopup_Vendors").Contains(GetPaymentMethod().UniqueName) || Metadata.Get("/Metadata/Settings/Withdraw.Comfirmation_EnabledPopup_Vendors").Contains(GetPaymentMethod().VendorID.ToString())) ? "true" : "false") : "false" %>;
    if (paymentPopupEnable) {
        $("#pnWidthDrawComfirmation").attr("target", "ConfirmationIframe");
    }
    var hidePopupFrame = function () {
        $(".ConfirmationBox.simplemodal-container").hide();
    };
    $(".ConfirmationClose").click(function(){hidePopupFrame();});
    $(".ConfirmButton").click(function (e) {    
        if (paymentPopupEnable) {
            $(".ConfirmationBox.simplemodal-container").appendTo("body").show();
            //$(".ConfirmationBox.simplemodal-container").click(function () {
            //    hidePopupFrame();
            //});
            $("#loading_block_all").hide();
            $(".ConfirmButton").toggleLoadingSpin(false);
        }
    });
</script>