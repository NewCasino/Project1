<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="Newtonsoft.Json" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>

<script language="C#" type="text/C#" runat="server">
    private bool ShowExtraFields(string UniqueName)
    {
        if (string.Equals(UniqueName, "PT_Maestro", StringComparison.InvariantCultureIgnoreCase)
            && (!string.IsNullOrEmpty(this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.IsHiddenIssueNumber"))
            && !string.Equals("No", this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.IsHiddenIssueNumber"),
            StringComparison.InvariantCultureIgnoreCase))
            )
        {
            return true;
        }
        else
        {
            bool bolRlt = string.Equals(UniqueName, "PT_MasterCard", StringComparison.InvariantCultureIgnoreCase) ||
                string.Equals(UniqueName, "PT_Switch", StringComparison.InvariantCultureIgnoreCase) ||
                string.Equals(UniqueName, "PT_Maestro", StringComparison.InvariantCultureIgnoreCase);
            if (bolRlt)
            {
                string[] arrCartPT = this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.HideIssueNumber").Split(new string[] { "," }, StringSplitOptions.RemoveEmptyEntries);
                foreach (string pt in arrCartPT)
                {
                    if (string.Compare(pt, UniqueName, true) == 0)
                    {
                        bolRlt = false;
                        break;
                    }
                }
            }
            return bolRlt;
        }
    }
    private
                    PaymentMethod currentPaymentMethod = PaymentMethodManager.GetPaymentMethods()
                         .FirstOrDefault(p => string.Equals(p.UniqueName, "PT_MasterCard", StringComparison.InvariantCultureIgnoreCase));
    private PaymentMethod[] FilterPaymentMethods(PaymentMethod[] paymentMethods
       , PaymentMethodCategory paymentMethodCategory
       )
    {
        var query = paymentMethods.Where(p => p.Category == paymentMethodCategory &&
            p.IsAvailable &&
            p.SupportDeposit &&
            DomainConfigAgent.IsVendorEnabled(p));

        int countryID = this.ViewData.GetValue<int>("CountryID", -1);
        string currency = this.ViewData.GetValue<string>("Currency", "EUR");

        if (countryID > 0)
            query = query.Where(p => p.SupportedCountries.Exists(countryID));

        //if (!string.IsNullOrWhiteSpace(currency))
        //    query = query.Where(p => p.SupportedCurrencies.Exists(currency));

        if (Profile.IsAuthenticated)
            query = query.Where(p => !Profile.IsInRole(p.DenyAccessRoleNames));

        var list = query.ToArray();
        query = query.Where(p => p.RepulsivePaymentMethods == null ||
            p.RepulsivePaymentMethods.Count == 0 ||
            !p.RepulsivePaymentMethods.Exists(p2 => paymentMethods.FirstOrDefault(p3 => p3.UniqueName == p2) != null)
            );

        return query.OrderBy(p => p.Ordinal).ToArray();
    }


    private List<SelectListItem> GetMonthList()
    {
        List<SelectListItem> list = new List<SelectListItem>();
        list.Add(new SelectListItem() { Text = this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.Month"), Value = "", Selected = true });

        for (int i = 1; i <= 12; i++)
        {
            list.Add(new SelectListItem() { Text = string.Format("{0:00}", i), Value = string.Format("{0:00}", i) });
        }

        return list;
    }

    private List<SelectListItem> GetExpiryYears()
    {
        List<SelectListItem> list = new List<SelectListItem>();
        list.Add(new SelectListItem() { Text = this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.Year"), Value = "", Selected = true });

        int startYear = DateTime.Now.Year;
        for (int i = 0; i < 20; i++)
        {
            list.Add(new SelectListItem() { Text = (startYear + i).ToString(), Value = (startYear + i).ToString() });
        }

        return list;
    }

    private List<SelectListItem> GetValidFromYears()
    {
        List<SelectListItem> list = new List<SelectListItem>();
        list.Add(new SelectListItem() { Text = this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.Year"), Value = "", Selected = true });

        int startYear = DateTime.Now.Year;
        for (int i = -20; i <= 0; i++)
        {
            list.Add(new SelectListItem() { Text = (startYear + i).ToString(), Value = (startYear + i).ToString() });
        }

        return list;
    }

</script>

<div class="quick-deposit-view">
    <div class="form-wrapper">
    <div class="RegDeposit">
            <form id="formRegisterPayCard" onsubmit="return false" method="post" action="<%= this.Url.RouteUrl("Deposit", new { @action = "RegisterPayCard", @vendorID="PaymentTrust"  }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">
                <div class="LeftPanel QuickDepositPanel">
                <%---------------------------------------------------------------
            Card Type
        ----------------------------------------------------------------%>
                <div id="CardType" class="inputfield ">
                    <div valign="top" class="inputfield_Label"><%=this.GetMetadata("/QuickDeposit/_Index_aspx.CardType_Label") %></div>
                    <div class="inputfield_Container">
                        <table class="inputfield_Table" cellpadding="0" cellspacing="0" border="0">
                            <tbody>
                                <tr>
                                    <td class="controls">
                                        <table cellpadding="0" cellspacing="0" border="0">
                                            <tbody>
                                                <tr>
                                                    <td>
                                                        <select id="ddlCardType" name="cardType">
                                                            <% 
                                                                PaymentMethod[] paymentMethods = PaymentMethodManager.GetPaymentMethods().ToArray();
                                                                foreach (PaymentMethodCategory category in PaymentMethodManager.GetCategories())
                                                                {
                                                                    var filteredMethods = FilterPaymentMethods(paymentMethods, category);
                                                                    if (filteredMethods.Length > 0)
                                                                    {
                                                                        foreach (PaymentMethod paymentMethod in filteredMethods)
                                                                        { %>
                                                            <option value="<%=paymentMethod.UniqueName %>"
                                                                <%=string.Equals(paymentMethod.UniqueName, "PT_MasterCard",StringComparison.InvariantCultureIgnoreCase) ? " selected='selected'" :"" %> data-visible="<%=ShowExtraFields(paymentMethod.UniqueName) %>" data-vendor="<%=paymentMethod.UniqueName.ToString() %>"><%=paymentMethod.GetTitleHtml() %></option>
                                                            <% 
                                                                        }
                                                                    }
                                                                }
                                                            %>
                                                        </select>
                                                    </td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </td>
                                    <td valign="top" class="indicator ">
                                        <div>&nbsp;</div>
                                    </td>
                                </tr>
                                <tr>
                                    <td colspan="2" class="hint"><span></span></td>
                                </tr>
                            </tbody>
                        </table>
                        <div style="clear: both"></div>
                    </div>
                    <script language="javascript" type="text/javascript">

                        $("#ddlCardType").change(function () {
                            if ($("#ddlCardType").val() == "PT_Maestro") {
                                $("#formRegisterPayCard").attr("src", "/Deposit/RegisterPayCard?vendorID=PaymentTrust");
                            } else {
                                window.location.href = '/Deposit/Prepare/' + $("#ddlCardType").find("option:selected").data("vendor");
                            }
                        });
                    </script>
                </div>
                <%=this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.IsHiddenIssueNumber") %>
                <%------------------------
Card Number
-------------------------%>
                <ui:InputField ID="fldCardNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
                    <labelpart><%= this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.CardNumber_Label").SafeHtmlEncode()%></labelpart>
                    <controlpart>
      <%: Html.TextBox("identityNumber", "", new 
        { 
            @maxlength = 16,
            @dir = "ltr",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.CardNumber_Empty")) 
                .Custom("validateCardNumber")
        } 
        )%>
    </controlpart>
                </ui:InputField>
                <%------------------------
    Card Holder Name
    -------------------------%>
                <ui:InputField ID="fldCardHolderName" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
                    <labelpart><%= this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.CardHolderName_Label").SafeHtmlEncode()%></labelpart>
                    <controlpart>
      <%: Html.TextBox("ownerName", "", new 
        { 
            @maxlength = 30,
            @validator = ClientValidators.Create().Required(this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.CardHolderName_Empty")) 
        } 
        )%>
    </controlpart>
                </ui:InputField>
            </div>

            <div class="RightPanel QuickDepositPanel">
                <%---------------------------------------------------------------
            Register a card
         ----------------------------------------------------------------%>
                <script language="javascript" type="text/javascript">
                    //<![CDATA[
                    $(document).ready(function () {
                        $('#fldCardNumber input[id="identityNumber"]').allowNumberOnly();
                    });
                    function validateCardNumber() {
                        var value = this;
                        var ret = /^(\d{9,16})$/.exec(value);
                        if (ret == null || ret.length == 0)
                            return '<%= this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.CardNumber_Invalid").SafeJavascriptStringEncode() %>';
                        return true;
                    }
                    //]]>
                </script>
                <%------------------------
                Valid From
              -------------------------%>
            <%--<% if (this.ShowExtraFields)
               {  %> --%>
                <ui:InputField ID="fldCardValidFrom" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
                    <labelpart><%= this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.ValidFrom_Label").SafeHtmlEncode()%></labelpart>
                    <controlpart>
      <table cellpadding="0" cellspacing="0" border="0">
        <tr>
          <td><%: Html.DropDownList("validFromMonth", GetMonthList(), new
                {
                    @id = "ddlValidFromMonth",
                } 
                )%></td>
          <td>&#160;</td>
          <td><%: Html.DropDownList("validFromYear", GetValidFromYears(), new
                {
                    @id = "ddlValidFromYear",
                } 
                )%>
            <%: Html.Hidden("validFrom","") %></td>
        </tr>
      </table>
    </controlpart>
                </ui:InputField>
                <script language="javascript" type="text/javascript">
                    //<![CDATA[
                    $(document).ready(function () {
                        var fun = function () {
                            var month = $('#ddlValidFromMonth').val();
                            var year = $('#ddlValidFromYear').val();
                            var value = '';
                            if (month.length > 0 && year.length > 0)
                                value = year + '-' + month + '-01';
                            $('#fldCardValidFrom input[name="validFrom"]').val(value);
                            if (value.length > 0)
                                InputFields.fields['fldCardValidFrom'].validator.element($('#fldCardValidFrom input[name="validFrom"]'));
                            else {
                                var _field = $('#fldCardValidFrom');
                                _field.removeClass("incorrect").removeClass("correct");
                                _field.find("label.error").hide();
                                _field.siblings(".bubbletip[elementid='" + _field.attr("id") + "']").hide();
                            }
                        };
                        $('#ddlValidFromMonth').change(fun);
                        $('#ddlValidFromYear').change(fun);
                    });
                    //]]>
                </script>
            <%--  <% } %>--%>
                <%------------------------
                Expiry Date
              -------------------------%>
                <ui:InputField ID="fldCardExpiryDate" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
                    <labelpart><%= this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.CardExpiryDate_Label").SafeHtmlEncode()%></labelpart>
                    <controlpart>
      <table cellpadding="0" cellspacing="0" border="0">
        <tr>
          <td><%: Html.DropDownList("expiryMonth", GetMonthList(), new
                {
                    @id="ddlExpiryMonth"
                } 
                )%></td>
          <td>&#160;</td>
          <td><%: Html.DropDownList("expiryYear", GetExpiryYears(), new
                {
                    @id = "ddlExpiryYear"
                } 
                )%>
            <%: Html.Hidden("expiryDate","", new 
                    {
                        @validator = ClientValidators.Create().Required(this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.CardExpiryDate_Empty")) 
                    } ) %></td>
        </tr>
      </table>
    </controlpart>
                </ui:InputField>
                <script language="javascript" type="text/javascript">
                    //<![CDATA[
                    $(document).ready(function () {
                        var fun = function () {
                            $(document).unbind("click");
                            var month = $('#ddlExpiryMonth').val();
                            var year = $('#ddlExpiryYear').val();
                            var value = '';
                            if (month.length > 0 && year.length > 0)
                                value = year + '-' + month + '-01';
                            $('#fldCardExpiryDate input[name="expiryDate"]').val(value);
                            //if (value.length > 0)
                            InputFields.fields['fldCardExpiryDate'].validator.element($('#fldCardExpiryDate input[name="expiryDate"]'));
                        };

                        $('#fldCardExpiryDate input[name="expiryDate"]').click(fun);

                        var isExpiryDateTriggered = false;
                        $(document).bind("VALID_CARD_EXPIRY_DATE", fun);
                        $('#ddlExpiryMonth').click(function (e) {
                            e.preventDefault();
                            isExpiryDateTriggered = true;
                            $(document).click(fun);
                            return false;
                        });
                        $('#ddlExpiryYear').click(function (e) {
                            e.preventDefault();
                            isExpiryDateTriggered = true;
                            $(document).click(fun);
                            return false;
                        });

                        $('#ddlExpiryMonth').change(function (e) {
                            e.preventDefault();
                            if (!isExpiryDateTriggered)
                                fun();
                        });
                        $('#ddlExpiryYear').change(function (e) {
                            e.preventDefault();
                            if (!isExpiryDateTriggered)
                                fun();
                        });
                    });
                    //]]>
                </script>
                <%------------------------
                Card Issue Number
            -------------------------%>
                <%--<% if (this.ShowExtraFields)
               {  %>--%>
                    <ui:InputField ID="fldCardIssueNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
                        <labelpart><%= this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.CardIssueNumber_Label").SafeHtmlEncode()%> <%= this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.Text_Optional").SafeHtmlEncode() %></labelpart>
                        <controlpart>
          <%: Html.TextBox("issueNumber", "", new 
            { 
                @maxlength = 16
            } 
            )%>
        </controlpart>
                    </ui:InputField>
                    <div class="floatGuideBox cardIssueNumberGuide" id="cardIssueNumberGuide"><%=this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.CardIssueNumber_Guide").HtmlEncodeSpecialCharactors() %> </div>
                    <script type="text/javascript">//<![CDATA[
                        $("#issueNumber").focus(function () {
                            $("#cardIssueNumberGuide").slideDown();
                        });
                        $("#issueNumber").focusout(function () {
                            $("#cardIssueNumberGuide").slideUp();
                        });

                        $(document).ready(function () { $("#cardIssueNumberGuide").hide(); });
                        //]]>
                    </script>
                <%--<% } %>--%>
                <%------------------------
                CVC 
              -------------------------%>
                    <ui:InputField ID="fldCVC" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
                        <labelpart><%= this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.CardSecurityCode_Label").SafeHtmlEncode()%></labelpart>
                        <controlpart>
          <%: Html.TextBox("cardSecurityCode", "", new 
            { 
                @maxlength = 4,
                @validator = ClientValidators.Create()
                .Required(this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.CardSecurityCode_Empty"))
                .Custom("validateCardSecurityCode") 
            } 
            )%>
        </controlpart>
                    </ui:InputField>
                    <div id="fldCVC2"><%: Html.Hidden("cardSecurityCode", "", new { @id = "cardSecurityCode" }) %></div>
                    <div class="floatGuideBox cardSecurityNumberGuide" id="cardSecurityCodeGuide"><%=this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.CardSecurityCode_Guide").HtmlEncodeSpecialCharactors() %> </div>
                    <script type="text/javascript">
                        //<![CDATA[
                        $(document).ready(function () {
                            $('#fldCVC input[id="cardSecurityCode"]').allowNumberOnly();
                            $("#cardSecurityCodeGuide").hide();
                        });

                        $("#formRegisterPayCard #cardSecurityCode").focus(function () {
                            $("#cardSecurityCodeGuide").slideDown();
                        });
                        $("#formRegisterPayCard #cardSecurityCode").focusout(function () {
                            $("#cardSecurityCodeGuide").slideUp();
                        });
                        //]]>
                    </script>
                    <center>
                <%: Html.Button(this.GetMetadata("/QuickDeposit/_Index_aspx.Button_Continue"), new { @id = "btnRegisterCardAndDeposit", @class="ContinueButton button" })%>
              </center>
                </div>
                <div class="clear"></div>
            </form>
        </div>
    <div id="terms_conditions_step" style="display: none"></div>
    <div id="confirm_step" style="display: none"></div>
    <div id="error_step" style="display: none">
        <center>
      <br />
      <br />
      <br />
      <%: Html.ErrorMessage("Internal Error.", false, new { id="deposit_error" })%>
      <br />
      <br />
      <br />
      <%: Html.Button(this.GetMetadata("/Deposit/_Prepare_aspx.Button_Back"), new { @id = "btnErrorBack", @onclick = "returnPreviousDepositStep(); return false;", @class="BackButton button" })%>
    </center>
    </div>
    <div class="clear"></div>
</div>
</div>
<script>
    var validateCardSecurityCodeInfo = '<%= this.GetMetadata("/Deposit/_PaymentTrustPayCard_ascx.CardSecurityCode_Invalid").SafeJavascriptStringEncode() %>';
    var GetPayCardsUrl = '';
    var Payments_Card_CountLimit = 3;
    var payCardJson = null;
    var saveSecurityKeyUrl = '<%= this.Url.RouteUrl( "Deposit", new { @action = "SaveSecurityKey" }).SafeJavascriptStringEncode() %>';
</script>
<script>
    var g_previousDepositSteps = new Array();
    function validateCardSecurityCode() {
        var value = this;
        var ret = /^(\d{3,4})$/.exec(value);
        if (ret == null || ret.length == 0)
            return validateCardSecurityCodeInfo;

        return true;
    }
    function showDepositError(errorText) {
        $('#error_step div.message_Text').text(errorText);
        g_previousDepositSteps.push($('div.deposit_steps > div:visible'));
        $('div.deposit_steps > div').hide();
        $('#error_step').show();
    }
    function returnPreviousDepositStep() {
        if (g_previousDepositSteps.length > 0) {
            $('div.deposit_steps > div').hide();
            g_previousDepositSteps.pop().show();
        }
    }
    function showDepositConfirmation(sid) {
        //window.location.href = "/Deposit/Prepare/PT_MasterCard?payCardID=" + sid; 
        g_previousDepositSteps.push($('div.deposit_steps > div:visible'));
        $('div.deposit_steps > div').hide();
        var url = '<%= this.Url.RouteUrl("Deposit", new { @action = "Confirmation", @paymentMethodName = currentPaymentMethod.UniqueName }).SafeJavascriptStringEncode() %>?sid=' + encodeURIComponent(sid);
          $('#confirm_step').show().html('<img border="0" src="/images/icon/loading.gif" />').load(url);
      }
      function showDepositTermsAndConditions(sid) {
          g_previousDepositSteps.push($('div.deposit_steps > div:visible'));
          $('div.deposit_steps > div').hide();
          var url = '<%= this.Url.RouteUrl("Deposit", new { @action = "BonusTC"}).SafeJavascriptStringEncode() %>?sid=' + encodeURIComponent(sid);
          $('#terms_conditions_step').show().html('<img border="0" src="/images/icon/loading.gif" />').load(url);
      }
      function validCardValidFrom() {
          var _field = $("#formRegisterPayCard #fldCardValidFrom");
          if (_field.length == 0)
              return true;

          var month = _field.find('#ddlValidFromMonth').val();
          var year = _field.find('#ddlValidFromYear').val();

          if ((month.length == 0 && year.length > 0) || (month.length > 0 && year.length == 0))
              return InputFields.fields['fldCardValidFrom'].validator.element($('#fldCardValidFrom input[name="validFrom"]'));
          else {
              _field.removeClass("incorrect");
              _field.find("label.error").hide();
              _field.siblings(".bubbletip[elementid='" + _field.attr("id") + "']").hide();
          }
          return true;
      }
      function validCardExpiryDate() {
          var $_tag = $('#fldCardExpiryDate input[name="expiryDate"]');
          $_tag.trigger('click');
          return InputFields.fields['fldCardExpiryDate'].validator.element($_tag);
      }

      $(document).ready(function () {
          $('#formRegisterPayCard').initializeForm();
          $("#fldGammingAccount").hide();
          $('#btnRegisterCardAndDeposit').click(function (e) {
              console.log("c");
              e.preventDefault();

              if (!isDepositInputFormValid() || !$('#formRegisterPayCard').valid() || !validCardExpiryDate() || !validCardValidFrom())
                  return false;

              $(this).toggleLoadingSpin(true);

              console.log("c");
              var options = {
                  dataType: "json",
                  type: 'POST',
                  success: function (json) {
                      if (!json.success) {
                          $('#btnRegisterCardAndDeposit').toggleLoadingSpin(false);
                          showDepositError(json.error);
                          return;
                      }

                      $('#fldCVC2 input[name="cardSecurityCode"]').val($('#fldCVC input[name="cardSecurityCode"]').val());
                      //__loadRecentPayCards(json.payCardID);
                      tryToSubmitDepositInputForm(json.payCardID, function () {
                          $('#btnRegisterCardAndDeposit').toggleLoadingSpin(false);
                      });
                  },
                  error: function (xhr, textStatus, errorThrown) {
                      $('#btnRegisterCardAndDeposit').toggleLoadingSpin(false);
                  }
              };
              console.log(options);
              $('#formRegisterPayCard').ajaxForm(options);
              $('#formRegisterPayCard').submit();
              console.log("b");
          });

          $(document).bind('DEPOSIT_TRANSACTION_PREPARED', function (e, sid) {
              var url = saveSecurityKeyUrl;
              var data = { sid: sid, securityKey: $('#fldCVC2 input[name="cardSecurityCode"]').val() };
              jQuery.getJSON(url, data, function (json) {
                  if (!json.success) {
                      showDepositError(json.error);
                      return;
                  }
              });
          });
      });
</script>
