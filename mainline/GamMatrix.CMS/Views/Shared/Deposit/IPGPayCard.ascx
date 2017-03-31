<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>

<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<%@ Import Namespace="System.Globalization" %>

<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec GetExistingPayCard()
    {
        return GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.IPG)
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

        if (ExistingPayCard == null)
            throw new Exception("IPG is not configrured in GmCore correctly, missing dummy pay card.");
        
        tabRecentCards.Attributes["Caption"] = PaymentTitle;
    }
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <tabs>

        <%---------------------------------------------------------------
            IPG
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards"  IsHtmlCaption="true" Selected="true">
            <form id="formIPGPayCard" method="post" action="<%= this.Url.RouteUrl("Deposit", new { @action = "RegisterPayCard", @vendorID=this.Model.VendorID }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">
                <%: Html.Hidden("bankName", this.Model.SubCode) %>
                <%: Html.Hidden("ipgPayCardID", ((ExistingPayCard == null) ? string.Empty : ExistingPayCard.ID.ToString(CultureInfo.InvariantCulture))) %>

                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithIPGPayCard", @class="ContinueButton button" })%>
                </center>
            </form>

        </ui:Panel>

    </tabs>
</ui:TabbedContent>

<script language="javascript" type="text/javascript">
    //<![CDATA[
    $(document).ready(function () {
        $('#formIPGPayCard').initializeForm();

        $('#btnDepositWithIPGPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid() || !$('#formIPGPayCard').valid())
                return false;

            $(this).toggleLoadingSpin(true);

            var payCardID = $('input[name="ipgPayCardID"]').val();
            if (payCardID.length > 0) {
                // <%-- post the prepare form --%>   
                tryToSubmitDepositInputForm(payCardID, function () {
                    $('#btnDepositWithIPGPayCard').toggleLoadingSpin(false);
                });
                return;
            }

            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {

                    if (!json.success) {
                        $('#btnDepositWithIPGPayCard').toggleLoadingSpin(false);
                        showDepositError(json.error);
                        return;
                    }
                    // <%-- the card is successfully registered, now prepare the transaction --%>
                    $('input[name="ipgPayCardID"]').val(json.payCardID);

                    // <%-- post the prepare form --%>   
                    tryToSubmitDepositInputForm(json.payCardID, function () {
                        $('#btnDepositWithIPGPayCard').toggleLoadingSpin(false);
                    });
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnRegisterCardAndDeposit').toggleLoadingSpin(false);
                    showDepositError(errorThrown);
                }
            };
            $('#formIPGPayCard').ajaxForm(options);
            $('#formIPGPayCard').submit();
        });

    });
        //]]>
</script>
