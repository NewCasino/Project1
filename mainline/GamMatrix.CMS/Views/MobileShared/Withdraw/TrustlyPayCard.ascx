<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="CM.Web.UI" %>

<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec GetDummyPayCard()
    {
        PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.Trustly)
            .Where(p => p.IsDummy)
            .FirstOrDefault();
        if (payCard == null)
            throw new Exception("Trustly is not configrured in GmCore correctly, missing dummy pay card.");
        return payCard;
    }
</script>

<div class="UiPasWithdrawal">
    <fieldset>
	    <legend class="Hidden">
		    <%= this.GetMetadata(".WithdrawToTrustly").SafeHtmlEncode()%>
	    </legend>
	    <p class="SubHeading WithdrawSubHeading">
		    <%= this.GetMetadata(".WithdrawToTrustly").SafeHtmlEncode()%>
	    </p>



        <div class="TabContent">
			<input type="hidden" name="payCardID" value="<%= GetDummyPayCard().ID %>"" />
		</div>
	</fieldset>
</div>