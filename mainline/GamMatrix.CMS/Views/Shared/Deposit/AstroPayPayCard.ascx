<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">


    protected PayCardInfoRec DummyCard { get; set; }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        DummyCard = GetDummyPayCard();
    }

    private PayCardInfoRec GetDummyPayCard()
    {
        PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.AstroPay)
            .Where(p => p.IsDummy)
            .FirstOrDefault();
        if (payCard == null)
        {

            List<PayCardInfoRec> userPayCards = GamMatrixClient.GetPayCards();

            string infoMessage = string.Empty;
            foreach (var userPayCard in userPayCards)
            {
                var paycardJson = new JavaScriptSerializer().Serialize(userPayCard);
                infoMessage += paycardJson + ",\n ";
            }

            Logger.Warning("PayCard", String.Format("Astropay dummy is null, other user cards: \n {0}", infoMessage));

            throw new Exception("AstroPay is not configrured in GmCore correctly, missing dummy pay card.");
        }
        return payCard;
    }

    private List<SelectListItem> GetMonthList()
    {
        List<SelectListItem> list = new List<SelectListItem>();
        list.Add(new SelectListItem() { Text = this.GetMetadata(".Month"), Value = "", Selected = true });

        for (int i = 1; i <= 12; i++)
        {
            list.Add(new SelectListItem() { Text = string.Format("{0:00}", i), Value = string.Format("{0:00}", i) });
        }

        return list;
    }

    private List<SelectListItem> GetExpiryYears()
    {
        List<SelectListItem> list = new List<SelectListItem>();
        list.Add(new SelectListItem() { Text = this.GetMetadata(".Year"), Value = "", Selected = true });

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
        list.Add(new SelectListItem() { Text = this.GetMetadata(".Year"), Value = "", Selected = true });

        int startYear = DateTime.Now.Year;
        for (int i = -20; i <= 0; i++)
        {
            list.Add(new SelectListItem() { Text = (startYear + i).ToString(), Value = (startYear + i).ToString() });
        }

        return list;
    }
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <tabs>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/AstroPayCard.Title) %>" Selected="true">
            <form id="formAstroPayPayCard" action="<%= this.Url.RouteUrl("Deposit", new { @action = "SaveAstroPay", @vendorID=this.Model.VendorID }).SafeHtmlEncode() %>" method="post" enctype="application/x-www-form-urlencoded">

                <%: Html.Hidden("sid", "") %>

                <%: Html.WarningMessage(this.GetMetadata(".Warning_Message"), false, new { @id="astroPayMessage"})%>

                <ui:InputField ID="fldCardNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".CardNumber_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.TextBox("cardNumber", "", new 
                        { 
                            @maxlength = 50,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".CardNumber_Empty"))
                        } 
                        )%>
	                </ControlPart>
                </ui:InputField>

                <ui:InputField ID="fldCardExpiryDate" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".CardExpiryDate_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <table cellpadding="0" cellspacing="0" border="0">
                            <tr>
                                <td>
                                <%: Html.DropDownList("expiryMonth", GetMonthList(), new
                                {
                                    @id="ddlExpiryMonth"
                                } 
                                )%>
                                </td>
                                <td>&#160;</td>
                                <td>
                                <%: Html.DropDownList("expiryYear", GetExpiryYears(), new
                                {
                                    @id = "ddlExpiryYear"
                                } 
                                )%>
                                <%: Html.Hidden("expiryDate","", new 
                                    {
                                        @validator = ClientValidators.Create().Required(this.GetMetadata(".CardExpiryDate_Empty")) 
                                    } ) %>
                                </td>
                            </tr>
                        </table>
	                </ControlPart>
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
                <ui:InputField ID="fldCVC" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".CardSecurityCode_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.TextBox("cardSecurityCode", "", new 
                        { 
                            @maxlength = 4,
                            @validator = ClientValidators.Create()
                            .Required(this.GetMetadata(".CardSecurityCode_Empty"))
                            .Custom("validateCardSecurityCode") 
                        } 
                        )%>
	                </ControlPart>
                </ui:InputField>
            
                <div class="floatGuideBox cardSecurityNumberGuide" id="cardSecurityCodeGuide" >
                    <%=this.GetMetadata(".CardSecurityCode_Guide").HtmlEncodeSpecialCharactors() %>
                </div> 
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
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithAstroPayPayCard", @class="ContinueButton button" })%>
                </center>
            </form>
        </ui:Panel>
    </tabs>
</ui:TabbedContent>

<script type="text/javascript">
    //<![CDATA[
    function validateCardSecurityCode() {
        var value = this;
        var ret = /^(\d{3,4})$/.exec(value);
        if (ret == null || ret.length == 0)
            return '<%= this.GetMetadata(".CardSecurityCode_Invalid").SafeJavascriptStringEncode() %>';

        return true;
    }

    function validCardExpiryDate() {
        var $_tag = $('#fldCardExpiryDate input[name="expiryDate"]');
        $_tag.trigger('click');
        return InputFields.fields['fldCardExpiryDate'].validator.element($_tag);
    }

    $(function () {

        $('#formAstroPayPayCard').initializeForm();

        $('#btnDepositWithAstroPayPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid() || !$('#formAstroPayPayCard').valid() || !validCardExpiryDate())
                return false;

            $(this).toggleLoadingSpin(true);

            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm('<%= DummyCard.ID.ToString() %>', function () {
                $('#btnDepositWithAstroPayPayCard').toggleLoadingSpin(false);
            });
        });


        // <%-- bind event to DEPOSIT_TRANSACTION_PREPARED --%>
        $(document).bind('DEPOSIT_TRANSACTION_PREPARED', function (e, sid) {
            $('#formAstroPayPayCard input[name="sid"]').val(sid);
            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    if (!json.success) {
                        $('#btnDepositWithAstroPayPayCard').toggleLoadingSpin(false);
                        showDepositError(json.error);
                        return;
                    }
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnDepositWithAstroPayPayCard').toggleLoadingSpin(false);
                    showDepositError(errorThrown);
                }
            };
            $('#formAstroPayPayCard').ajaxForm(options);
            $('#formAstroPayPayCard').submit();
        });
    });
    //]]>
</script>
