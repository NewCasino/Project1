<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec PayCard { get; set; }
    private PayCardInfoRec GetExistingPayCard()
    {
        if (this.PayCard == null)
        {
            this.PayCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.TxtNation)
            .OrderByDescending(e => e.LastSuccessDepositDate).FirstOrDefault();
        }
        if (this.PayCard == null)
            throw new InvalidOperationException("This payment method is not configured in GmCore.");
        return this.PayCard;
    }

    private string GetAvailableAmounts()
    {
        var request = new GamMatrixAPI.GetAvailableTxtNationAmountsRequest();

        using (GamMatrixClient client = new GamMatrixClient())
        {
            request = client.SingleRequest<GetAvailableTxtNationAmountsRequest>(request);
        }
        
        return string.Join(",", request.AvailableAmounts.ToArray());
    }
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

        <%---------------------------------------------------------------
            Moneybookers
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/TxtNation.Title) %>" Selected="true">
            <form id="formTxtNationPayCard" onsubmit="return false">
                <%------------------------
                    Email
                    
                    The MB deposit is a bit different from other payment method.
                    When user first deposit, use a dummy card and there is nothing to fill for the user.
                    And after a successful deposit, the email field is shown and filled with the email address
                -------------------------%>    
                <%: Html.Hidden("txtNationPayCardID", GetExistingPayCard().ID.ToString())%>
                <% PayCardInfoRec payCard = GetExistingPayCard();
                   if (!payCard.IsDummy && !string.IsNullOrWhiteSpace(payCard.DisplayNumber) )
                   { %>
                
                <ui:InputField ID="fldEmail" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".Email_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>

                        
                        <%: Html.TextBox("identityNumber", GetExistingPayCard().DisplayNumber, new 
                        { 
                            @maxlength = 255,
                            @dir = "ltr",
                            @readonly = "readonly",
                        } 
                        )%>                        
	                </ControlPart>
                </ui:InputField>


                <% } %>
                <br />
                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithTxtNationPayCard", @class="ContinueButton button" })%>
                </center>
            </form>
              <script type="text/javascript">
                  var txtNationTransID = null;
                  var transactionIdChecking = false;
                  var transactionIdInterval = null;
                  var feeText = '<%= this.GetMetadata(".FeeText") %>';

                  $(function () {
                      initAmountsDropDown();
                      
                      $('#ddlCurrency').val('GBP');
                      $('#ddlCurrency option[value!="GBP"]').remove();

                      $('#btnDepositWithTxtNationPayCard').click(function(){
                          $('#btnDepositWithTxtNationPayCard').toggleLoadingSpin(true);

                          getTxtNationRedirectUrl(function(data){
                              $('#btnDepositWithTxtNationPayCard').toggleLoadingSpin(false);

                              if (data.Success == true){
                                  var redirectUrl = data.Data;
                                  txtNationTransID = data.TxtNationTransID;

                                  g_previousDepositSteps.push($('div.deposit_steps > div:visible'));
                                  $('div.deposit_steps > div').hide();
                                  var url = '<%= this.Url.RouteUrl("Deposit", new { @action = "Confirmation", @paymentMethodName = "TxtNation" }).SafeJavascriptStringEncode() %>?sid=' + $('#lstAmounts').val();
                                  $('#confirm_step').show().html('<img border="0" src="/images/icon/loading.gif" />').load(url, function(){
                                      window.redirectToReceiptPage = function(url){
                                          if (url.indexOf('Error') > -1){
                                              setTimeout(function(){
                                                  document.location.href = '<%= this.Url.RouteUrl("Deposit", new { @action = "Error" }).SafeJavascriptStringEncode() %>';
                                              }, 1000);
                                          }else{
                                              transactionIdInterval = setInterval(GetTxtNationSessionId, 5000);
                                          }

                                          return '1';
                                      }

                                      var creditRow = $('.confirmation_row_credit .name');
                                      creditRow.text(creditRow.text() + ' ' + feeText);

                                      $('.ConfirmButton.button').click(function(){
                                          $('.deposit-block-dialog-operations li:first a').attr('href', '/Deposit/ReceiptTxtNation?txtNationTransID=' + txtNationTransID);

                                          window.txtNationPopup = window.open(redirectUrl, '_blank');

                                          return false;
                                      });
                                  });
                              } else{
                                  showDepositError(data.Data);
                              }   
                          });
                      });
                  });

                  function initAmountsDropDown() {
                      var strAmounts = '<%= GetAvailableAmounts() %>';

                      var txtAmount = $('#fldCurrencyAmount #txtAmount');
                      var amountContainer = txtAmount.parent();

                      txtAmount.remove();

                      var lstAmounts = $('<select id="lstAmounts" class="lst-amounts select" />');

                      var strAmountsArr = strAmounts.split(',');

                      for (var i = 0; i < strAmountsArr.length; i++) {
                          lstAmounts.prepend($('<option/>').attr('value', strAmountsArr[i]).text(parseFloat(strAmountsArr[i]).toFixed(2)));
                      }

                      amountContainer.append(lstAmounts);
                  }

                  function getTxtNationRedirectUrl(callback) {
                      var amount = parseFloat($('#lstAmounts').val());
                      var userId = <%= Profile.UserID %>;
                      var windowSize = "large";
                      var bonusCode = $("#bonusCode").val();
                      var bonusVendor = $("#bonusVendor").val();
                      var txtGammingAccountID = parseInt($('#txtGammingAccountID').val());

                      $.post("/Deposit/getTxtNationRedirectUrl",
                          { amount: amount, userId: userId, windowSize: windowSize, bonusCode: bonusCode, bonusVendor: bonusVendor, gammingAccountID: txtGammingAccountID },
                          function (data) {
                              if (callback){
                                  callback(data);
                              }
                          }, "json");
                  }

                  function GetTxtNationSessionId(){
                      if (transactionIdChecking == true){
                          return;
                      }

                      transactionIdChecking = true;

                      $.post("/Deposit/GetTxtNationSessionId",
                          { txtNationTransID: txtNationTransID },
                          function (data) {
                              transactionIdChecking = false;

                              if (data.Success == true && data.SessionId){
                                  clearInterval(transactionIdInterval);
                                  $('#btnDepositWithTxtNationPayCard').toggleLoadingSpin(false);

                                  document.location.href = '/Deposit/Receipt/TxtNation/' + data.SessionId;
                              }
                          }, "json");
                  }
              </script>
        </ui:Panel>
    </Tabs>
</ui:TabbedContent>


<script type="text/javascript">
//<![CDATA[
    $(function () {
        $('#formTxtNationPayCard').initializeForm();
    });
//]]>
</script>
