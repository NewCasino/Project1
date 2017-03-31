<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="GamMatrix.CMS.Controllers.Shared" %>
<script language="C#" type="text/C#" runat="server">
    private GetTransInfoRequest GetTransactionInfo()
    {
        return this.ViewData["getTransInfoRequest"] as GetTransInfoRequest;
    }

    private PrepareTransRequest GetPrepareTransRequest()
    {
        return this.ViewData["prepareTransRequest"] as PrepareTransRequest;
    }

    private ProcessTransRequest GetProcessTransRequest()
    {
        return this.ViewData["processTransRequest"] as ProcessTransRequest;
    }

    private ProcessAsyncTransRequest GetProcessAsyncTransRequest()
    {
        return this.ViewData["processAsyncTransRequest"] as ProcessAsyncTransRequest;
    }

    private string GetTranJson()
    {
        if (GetPrepareTransRequest() != null)
        {
            return string.Format(CultureInfo.InvariantCulture, "{{ 'CreditCurrency':'{0}', 'CreditAmount':{1:F2}, 'TransactionID':'{2:D}','DepositFee':'{3}' }}"
                , GetPrepareTransRequest().Record.CreditCurrency
                , GetPrepareTransRequest().Record.CreditAmount
                , GetTransactionInfo().TransID
                , this.Model.DepositProcessFee.Percentage
                );
        }
        else
        {
            return string.Empty;
        }
    }

    private string GetCreditMessage()
    {
        return string.Format(this.GetMetadata(".Receipt_Credit")
            , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", GetPrepareTransRequest().Record.CreditPayItemVendorID.ToString()))
            );
    }

    private string GetDebitMessage()
    {
        PayCardRec payCard = GamMatrixClient.GetPayCard(GetPrepareTransRequest().Record.DebitPayCardID);

       if (Model.VendorID == VendorID.MoneyMatrix && Model.UniqueName == "MoneyMatrix")
            return this.GetMetadataEx(".Debit_Card", payCard.DisplayName).SafeHtmlEncode();

        if (this.Model.VendorID != VendorID.PaymentTrust)
            return string.Format(this.GetMetadata(".Receipt_Debit").SafeHtmlEncode(), this.Model.GetTitleHtml());

        if (payCard != null)
            return string.Format(this.GetMetadata(".Debit_Card").SafeHtmlEncode(), payCard.DisplayNumber);

        return string.Empty;
    }
</script>
<asp:content contentplaceholderid="cphHead" runat="Server">
  <meta http-equiv="Pragma" content="no-cache" />
  <meta http-equiv="Cache-Control" content="no-cache" />
  <meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT" />
  <meta http-equiv="expires" content="0" />
</asp:content>
<asp:content contentplaceholderid="cphMain" runat="Server">
  <div id="deposit-wrapper" class="content-wrapper">
    <%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
    <ui:Panel runat="server" ID="pnDeposit">
      <% Html.RenderPartial("PaymentMethodDesc", this.Model); %>
      <div id="receipt_step">
        <center>
          <br />
          <%: Html.SuccessMessage( this.GetMetadata(".Success_Message") ) %>
          <%-------------------------------
    UKash or BoCash receipt
-------------------------------%>
          <% if (this.Model.VendorID == VendorID.Ukash || this.Model.VendorID == VendorID.BoCash)
   {
       ProcessTransRequest processTransRequest = GetProcessTransRequest();
       if (processTransRequest != null &&
           processTransRequest.ResponseFields.ContainsKey("changeIssueVoucherNumber") &&
           !string.IsNullOrWhiteSpace(processTransRequest.ResponseFields["changeIssueVoucherNumber"]))
       {%>
          <br />
          <br />
          <%: Html.WarningMessage(this.GetMetadata(".Ukash_Notes"), false, new { @id = "ukashNotes" })%>
          <br />
          <table cellpadding="0" cellspacing="0" border="1" rules="all" class="confirmation_table receipt_table_ukash">
            <tr>
              <td class="name"><%= this.GetMetadata(".Ukash_Number") %></td>
              <td class="value"><%= processTransRequest.ResponseFields["changeIssueVoucherNumber"].SafeHtmlEncode() %></td>
            </tr>
            <tr>
              <td class="name"><%= this.GetMetadata(".Ukash_Currency") %></td>
              <td class="value"><%= processTransRequest.ResponseFields["changeIssueVoucherCurr"].SafeHtmlEncode()%></td>
            </tr>
            <tr>
              <td class="name"><%= this.GetMetadata(".Ukash_Value") %></td>
              <td class="value"><%= processTransRequest.ResponseFields["changeIssueAmount"].SafeHtmlEncode()%></td>
            </tr>
            <tr>
              <td class="name"><%= this.GetMetadata(".Ukash_Expiry_Date")%></td>
              <td class="value"><%= DateTime.Parse(processTransRequest.ResponseFields["changeIssueExpiryDate"]).ToString( "dd/MM/yyyy" )%></td>
            </tr>
          </table>
          <%   }
   } %>
          <br />
          <%: Html.InformationMessage(this.GetMetadata(".Information_Message"), false, new { @id = "receiptInformationMessage" })%>
          <br />
          <%------------------------
    The receipt table
  ------------------------%>
          
       <% if (GetTransactionInfo() != null )
       {
            %>
            
          <table cellpadding="0" cellspacing="0" border="1" rules="all" class="confirmation_table receipt_table">
            <tr class="receipt_row_credit">
              <td class="name"><%= GetCreditMessage().SafeHtmlEncode() %></td>
              <td class="value"><%= MoneyHelper.FormatWithCurrency( GetTransactionInfo().PostingData[1].Record.Currency
                              , GetTransactionInfo().PostingData[1].Record.Amount 
                              ) %></td>
            </tr>    
              
              <%      
    if (GetTransactionInfo().FeeData != null)
    {
        foreach (TransFeeData fee in GetTransactionInfo().FeeData)
        {
               %>
              <tr class="receipt_row_fee">
                <td class="name"><%= this.GetMetadata(".Receipt_Fee")%></td>
                <td class="value"><%= MoneyHelper.FormatWithCurrency(fee.Record.RealCurrency, fee.Record.FeeAmount) %></td>
               </tr>
             <%
        }
    }
    try
    {
        TransInfoRec transInfo = GetTransactionInfo().TransData;
        if (!string.IsNullOrWhiteSpace(transInfo.TransExternalReference3) &&
          (transInfo.TransExternalReference3.IndexOf("TSI") > 0
          || transInfo.TransExternalReference3.IndexOf("SmartCheque") > 0

          ))
        {

               %>
            <tr class="receipt_row_debit_vouchers">
              <td class="name"><%= this.GetMetadata(".DebitVouchers")%></td>
              <td class="value"><% 
                      JavaScriptSerializer jss = new JavaScriptSerializer();
                      TSIInfo data = jss.Deserialize<TSIInfo>(transInfo.TransExternalReference3);
                      if ((string.Equals(data.Type, "TSI", StringComparison.InvariantCultureIgnoreCase) ||
                        string.Equals(data.Type, "SmartCheque", StringComparison.InvariantCultureIgnoreCase)) &&
                        !string.IsNullOrWhiteSpace(this.GetMetadata(".DebitVouchers_DataFormat")))
                      {
                          Response.Write(
                              string.Format(this.GetMetadata(".DebitVouchers_DataFormat"),
                              data.Vouchers[0].Code,
                              data.Vouchers[0].Amount,
                              data.Vouchers[0].Currency));
                      } 
                          %></td>
            </tr>
            <%  
                  }
                  else
                  {
              %>
            <tr class="receipt_row_debit_vouchers"  style="display:none;">
              <td class="name"><%= this.GetMetadata(".DebitVouchers")%></td>
              <td class="value">N/A</td>
            </tr>
            <%      
                  }
              }
              catch (Exception ex)
              {
                 %>
            <tr class="receipt_row_debit_vouchers" style="display:none;">
              <td class="name"><%= this.GetMetadata(".DebitVouchers")%></td>
              <td class="value"><%=ex.ToString() %></td>
            </tr>
            <%     
              }
                             //  GetTransactionInfo().TransData.TransExternalReference3
                  %>
            <tr class="receipt_row_transactionid">
              <td class="name"><%= this.GetMetadata(".Transaction_ID").SafeHtmlEncode() %></td>
              <td class="value"><%= GetTransactionInfo().TransID %></td>
            </tr>
            <tr class="receipt_row_datetime">
              <td class="name"><%= this.GetMetadata(".Date_Time").SafeHtmlEncode() %></td>
              <td class="value"><%= GetTransactionInfo().TransData.TransCompleted.ToString("dd/MM/yyyy HH:mm:ss"
                              , System.Globalization.DateTimeFormatInfo.InvariantInfo).SafeHtmlEncode() %></td>
            </tr>
            <tr class="receipt_row_debit">
              <td class="name"><%= GetDebitMessage() %></td>
              <td class="value"><%= MoneyHelper.FormatWithCurrency( GetTransactionInfo().PostingData[0].Record.Currency
                              , GetTransactionInfo().PostingData[0].Record.Amount 
                              ) %></td>
            </tr>
          </table>

      <% 
        } // if (GetTransactionInfo() != null && GetTransactionInfo().FeeData != null) 
      %> 
          
            <br />
          <%  %>
          <center>
            <%: Html.Button(this.GetMetadata(".Button_Print"), new { @onclick = "window.print()", @type = "button", @class="PrintButton button" })%>
            <%: Html.Button( this.GetMetadata(".Button_Back")
    , new { @onclick = string.Format("self.location='{0}';", this.Url.RouteUrl( "Deposit", new { @action = "Index" }).SafeJavascriptStringEncode())
    , @type = "button", @class="BackButton button" }
    )%>
          </center>
        </center>
      </div>
    </ui:Panel>
  </div>
<script type="text/javascript">
    try {
        if (self.parent !== null && self.parent != self) {
            var targetOrigin = '<%=this.GetMetadata("/Deposit/_Prepare_aspx.TargetOriginForPostMessage").SafeJavascriptStringEncode().DefaultIfNullOrWhiteSpace("") %>';
            if (targetOrigin.trim() == '') {
                targetOrigin = top.window.location.href;
            }

            var amount = parseFloat("<%=GetTransactionInfo() != null ? GetTransactionInfo().PostingData[1].Record.Amount.ToString()  : "0.00" %>");
            window.top.postMessage('{"user_id":<%=CM.State.CustomProfile.Current.UserID %>, "message_type": "deposit_result", "success": true, "message": "<%=this.GetMetadata(".Success_Message").Replace("\n", "")%>", "amount": "' + amount + '", "currency": "<%=GetTransactionInfo() != null ? GetTransactionInfo().PostingData[0].Record.Currency : "EUR"%>"}', targetOrigin);
        }
    } catch (e) { console.log(e); }

    try { $(".ConfirmationBox.simplemodal-container", parent.document.body).hide(); 
        if( $(".ConfirmationBox.simplemodal-container", parent.document.body).length > 0 && parent.location.href != this.location.href){
            parent.location.href=this.location.href;
        }
    } catch (err) { console.log(err);}
    $(window).load(function () {
        $(document).trigger("BALANCE_UPDATED");
    });
    $(function () {
        $(document).trigger("DEPOSIT_COMPLETED", <%= GetTranJson() %>);
    });
    <%=this.GetMetadata(".Receipt_Script").SafeJavascriptStringEncode()%>
</script>
  <%  Html.RenderPartial("ReceiptBodyPlus", this.ViewData); %>
</asp:content>
