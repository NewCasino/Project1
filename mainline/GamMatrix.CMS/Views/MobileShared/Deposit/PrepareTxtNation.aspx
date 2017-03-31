<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareTxtNationViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>


<script runat="server">
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

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>

<asp:content contentplaceholderid="cphMain" runat="Server">

<div id="DepositPrepareBox" class="UserBox CenterBox DepositBox DepositOptionsList DepositStep3 DepositPrepareBox StyleV2" data-step="3">
        <div class="BoxContent DepositContent" id="DepositContent">
        <% if (!Settings.MobileV2.IsV2DepositProcessEnabled)
           { %>
    <% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
        <% } %>
<form action="<%= this.Url.RouteUrl("Deposit", new { @action = "PrepareTxtNationTransaction", @paymentMethodName = Model.PaymentMethod.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPreparePT" class="GeneralForm DepositForm DepositPrepare">
     <%: Html.Hidden( "windowSize", "small", new { @id = "hWindowSize" }) %>
<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>

            <fieldset>
            <legend class="Hidden">
            <%= this.GetMetadata(".CreditCard").SafeHtmlEncode() %>
            </legend>
                <%: Html.Hidden( "payCardID", string.Empty, new { @id = "hCreditCardPayCardID" }) %>


                <%-- Existing Card --%>
            <div class="TabContent" id="tabExistingCard">
                 <%: Html.Hidden("txtNationPayCardID", GetExistingPayCard().ID.ToString())%>
<ul class="FormList">

    <%--------------------------
        Existing Card
      --------------------------%>
    
            <% var payCard = GetExistingPayCard();
               if (!payCard.IsDummy && !string.IsNullOrEmpty(payCard.DisplayNumber))
               { %>
            <li class="FormItem">
            <label class="FormLabel" for="depositIdentityNumber"><%= this.GetMetadata(".Email_Label").SafeHtmlEncode() %></label>
                         <%: Html.TextBox("identityNumber", GetExistingPayCard().DisplayNumber, new 
                        { 
                            @maxlength = 255,
                            @dir = "ltr",
                            @readonly = "readonly",
                        }) %>

			            <span class="FormStatus">Status</span>
			            <span class="FormHelp"></span>
            </li>
            <%} %>

</ul>

                </div>
            </fieldset>

            <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>

</form>
    </div>
</div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="true">
<script>
    //<![CDATA[
    function initAmountsDropDown() {
        var strAmounts = '<%= GetAvailableAmounts() %>';

        var txtAmount = $('#fldAmount #selectAmount'),
            amountContainer = $('#fldAmount div.AmountContainer');



        var lstAmounts = $('<select id="lstAmounts" class="FormInput lst-amounts select" />');

       var strAmountsArr = strAmounts.split(',');

       for (var i = 0; i < strAmountsArr.length; i++) {
           lstAmounts.prepend($('<option/>').attr('value', strAmountsArr[i]).text(parseFloat(strAmountsArr[i]).toFixed(2)));
       }

       lstAmounts.change(function () {
           txtAmount.val(lstAmounts.val());
       });

       txtAmount.val(lstAmounts.val());

       amountContainer.hide();
       amountContainer.parent().removeClass('AmountBox');
       lstAmounts.insertAfter(amountContainer);

       $("#DepositExtraButtons").hide();
   }

    $(function () {
        CMS.mobile360.Generic.input();
        initAmountsDropDown();
        setTimeout(function () {
            $('#selectCurrency').val('GBP')
            .trigger("change");
        }, 500);
        
        //$('#selectCurrency option[value!="GBP"]').remove();


    });
    //]]>
</script>
</ui:MinifiedJavascriptControl>

</asp:content>

