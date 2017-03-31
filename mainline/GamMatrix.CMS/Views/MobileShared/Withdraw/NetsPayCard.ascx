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

<div class="UiPasWithdrawal">
    <fieldset>
	    <legend class="Hidden">
		    <%= this.GetMetadata(".Withdraw_Message").SafeHtmlEncode()%>
	    </legend>
	    <p class="SubHeading WithdrawSubHeading">
		    <%= this.GetMetadata(".Withdraw_Message").SafeHtmlEncode()%>
	    </p>



        <div class="TabContent">
			<input type="hidden" name="payCardID" value="<%= DummyCard.ID %>" />
		</div>
	</fieldset>
</div>