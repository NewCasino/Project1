<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>

<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<%@ Import Namespace="System.Globalization" %>

<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec GetExistingPayCard()
    {
        return GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.PugglePay)
                .Where(e => e.IsDummy == true)
                .OrderByDescending(e => e.Ins)
                .FirstOrDefault();
    }

    private string PaymentTitle;
    private string UserMobile = "";
    private PayCardInfoRec ExistingPayCard;

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        string paymentTitleMetadataPath = string.Format("/Metadata/PaymentMethod/{0}.Title", this.Model.UniqueName);
        PaymentTitle = this.GetMetadata(paymentTitleMetadataPath);

        ExistingPayCard = GetExistingPayCard();

        //if (ExistingPayCard == null)
        //{
        //    ExistingPayCard = new PayCardInfoRec();
        //    ExistingPayCard.ID = -10000 - (int)VendorID.PugglePay;
        //}

        if (ExistingPayCard == null)
            throw new Exception("PugglePay is not configrured in GmCore correctly, missing dummy pay card.");
        
        tabRecentCards.Attributes["Caption"] = PaymentTitle;
    }
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <tabs>

        <%---------------------------------------------------------------
            PugglePay
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards"  IsHtmlCaption="true" Selected="true">
            <form id="formPugglePayPayCard" method="post" action="<%= this.Url.RouteUrl("Deposit", new { @action = "RegisterPayCard", @vendorID=this.Model.VendorID }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">
                <%: Html.Hidden("bankName", this.Model.SubCode) %>
                <%: Html.Hidden("pugglePayPayCardID", ((ExistingPayCard == null) ? string.Empty : ExistingPayCard.ID.ToString(CultureInfo.InvariantCulture))) %>

                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithPugglePayPayCard", @class="ContinueButton button" })%>
                </center>
            </form>

        </ui:Panel>

    </tabs>
</ui:TabbedContent>

<script language="javascript" type="text/javascript">
    //<![CDATA[
    $(document).ready(function () {
        //showDepositConfirmation('1bb38c5aff2e4684aa99c9b771d3e462');
        //return;
        $('#formPugglePayPayCard').initializeForm();

        $('#btnDepositWithPugglePayPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid() || !$('#formPugglePayPayCard').valid())
                return false;

            $(this).toggleLoadingSpin(true);

            var payCardID = $('input[name="pugglePayPayCardID"]').val();
            if (payCardID.length > 0) {
                // <%-- post the prepare form --%>   
                tryToSubmitDepositInputForm(payCardID, function () {
                    $('#btnDepositWithPugglePayPayCard').toggleLoadingSpin(false);
                });
                return;
            }

            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {

                    if (!json.success) {
                        $('#btnDepositWithPugglePayPayCard').toggleLoadingSpin(false);
                        showDepositError(json.error);
                        return;
                    }
                    // <%-- the card is successfully registered, now prepare the transaction --%>
                    $('input[name="pugglePayPayCardID"]').val(json.payCardID);

                    // <%-- post the prepare form --%>   
                    tryToSubmitDepositInputForm(json.payCardID, function () {
                        $('#btnDepositWithPugglePayPayCard').toggleLoadingSpin(false);
                    });
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnRegisterCardAndDeposit').toggleLoadingSpin(false);
                    showDepositError(errorThrown);
                }
            };
            $('#formPugglePayPayCard').ajaxForm(options);
            $('#formPugglePayPayCard').submit();
        });

    });
    //]]>
</script>
