<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec DummyPayCard { get; set; }

    protected override void OnInit(EventArgs e)
    {
        List<PayCardInfoRec> payCards = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.PayAnyWay);
        this.DummyPayCard = payCards.FirstOrDefault(p => p.IsDummy);

        if (this.DummyPayCard == null)
            throw new InvalidOperationException("This payment method is not configured in GmCore.");
        
        base.OnInit(e);
    }

    protected override void OnPreRender(EventArgs e)
    {
        tabRecentCards.Attributes["Caption"] = this.Model.GetTitleHtml();
        base.OnPreRender(e);
    }
</script>


<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

        <%---------------------------------------------------------------
            Moneta
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Selected="true">
            <form id="formMonetaPayCard" onsubmit="return false">


                <br />
                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithMonetaPayCard", @class="ContinueButton button" })%>
                </center>
            </form>

        </ui:Panel>

    </Tabs>
</ui:TabbedContent>


<script type="text/javascript">
//<![CDATA[
    $(function () {
        $('#formMonetaPayCard').initializeForm();

        $('#btnDepositWithMonetaPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid())
                return false;

            $(this).toggleLoadingSpin(true);

            var payCardID = '<%= this.DummyPayCard.ID.ToString()  %>';
            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm(payCardID, function () {
                $('#btnDepositWithMonetaPayCard').toggleLoadingSpin(false);
            });
        });
    });
//]]>
</script>
