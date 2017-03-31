<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>

<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec GetDummyPayCard()
    {
        PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.IPG)
            .Where(p => p.IsDummy)
            .FirstOrDefault();
        if (payCard == null)
            throw new Exception("IPG is not configrured in GmCore correctly, missing dummy pay card.");
        return payCard;
    }
</script>

<%---------------------------------------------------------------
Neteller
----------------------------------------------------------------%>
<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

        <%---------------------------------------------------------------
                Existing Cards
        ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" Caption="IPG">
            <form id="formIPGPayCard" onsubmit="return false">

               

                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @class="BackButton button",  @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnWithdrawWithIPGPayCard", @class="ContinueButton button" })%>
                </center>
            </form>
        </ui:Panel>

        
    </Tabs>
</ui:TabbedContent>

<script type="text/javascript">
    $(function () {
        $('#formIPGPayCard').initializeForm();
        $('#tabbedPayCards').selectTab('tabRecentCards', true);

        $('#btnWithdrawWithIPGPayCard').click(function (e) {
            e.preventDefault();

            if (!isWithdrawInputFormValid() || !$('#formIPGPayCard').valid())
                return;

            $('#btnWithdrawWithIPGPayCard').toggleLoadingSpin(true);
            tryToSubmitWithdrawInputForm('<%= GetDummyPayCard().ID %>'
        , function () { $('#btnWithdrawWithIPGPayCard').toggleLoadingSpin(false); });
    });

});
</script>