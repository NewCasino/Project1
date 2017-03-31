<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>

<script language="C#" type="text/C#" runat="server">
    
    protected PayCardInfoRec DummyCard = null;

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        DummyCard = GetDummyPayCard();
    }
    
    private PayCardInfoRec GetDummyPayCard()
    {
        PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.Nets)
            .Where(p => p.IsDummy)
            .FirstOrDefault();
        if (payCard == null)
        {
            throw new Exception("Nets is not configrured in GmCore correctly, missing dummy pay card.");
        }
        return payCard;
    }

</script>

<%---------------------------------------------------------------
Neteller
----------------------------------------------------------------%>
<ui:TabbedContent ID="tabbedPayCards" runat="server" >
    <Tabs>

        <%---------------------------------------------------------------
                Existing Cards
        ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" Caption="Nets" >
            <form id="formNetsPayCard" onsubmit="return false">
                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @class="BackButton button",  @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnWithdrawWithNetsPayCard", @class="ContinueButton button" })%>
                </center>
            </form>
        </ui:Panel>

        
    </Tabs>
</ui:TabbedContent>

<script type="text/javascript">
$(function () {
    $('#formNetsPayCard').initializeForm();
    $('#tabbedPayCards').selectTab('tabRecentCards', true);

    $('#btnWithdrawWithNetsPayCard').click(function (e) {
        e.preventDefault();

        if (!isWithdrawInputFormValid() || !$('#formNetsPayCard').valid())
            return;

        $('#btnWithdrawWithNetsPayCard').toggleLoadingSpin(true);
        tryToSubmitWithdrawInputForm( '<%= DummyCard.ID %>'
        , function () { $('#btnWithdrawWithNetsPayCard').toggleLoadingSpin(false); });
    });

});    
</script>