<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
   
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="DialogHeader">
    <span class="DialogIcon">ArtemisBet</span>
    <h3 class="DialogTitle"><%= this.GetMetadata(".DialogTitle") %></h3>
    <p class="DialogInfo"><%= this.GetMetadata(".DialogInfo") %></p>
</div>
<div class="Breadcrumbs" role="navigation">
        <ul class="BreadMenu Container" role="menu">
            <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
                </a>
            </li>
            <li class="BreadItem BreadCurrent" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/DepositPage/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/DepositPage/.Name") %></span>
                </a>
            </li>
        </ul>
    </div>
<div id="deposit-wrapper" class="content-wrapper">
<h1 id="ProfileTitle" class="ProfileTitle"> <%: this.GetMetadata(".HEAD_TEXT") %> </h1>
<ui:Panel runat="server" ID="pnDeposit">

<%: Html.AnonymousCachedPartial("PaymentMethodFilterView", this.ViewData)%>

</ui:Panel>
</div>


<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
jQuery('body').addClass('DepositPage');
jQuery('.inner').addClass('ProfileContent DepositContent');
jQuery('.MainProfile').addClass('MainDeposit');
jQuery('.sidemenu li').addClass('PMenuItem');
jQuery('.sidemenu li span').addClass('PMenuLinkContainer');
jQuery('.sidemenu li span a').addClass('ProfileMenuLinks');

setTimeout(function(){
jQuery('.ProfileContent').prepend(jQuery('#ProfileTitle'));
},1);


$(function () {
    var movePaycard = function (categoryName, cardKey) {
        var toTableBody = $('#payment-methods-wrapper table[data-category="'+categoryName+'"] tbody');
        var toBeRemovedTr = $('#payment-methods-wrapper tr[data-resourcekey$="' + cardKey + '"]');
        if (toTableBody.length > 0 && toBeRemovedTr.length > 0) {
            if (toBeRemovedTr.parent().find("tr").length > 1) {
                //more than one
            } else {
                toBeRemovedTr.parents('table')
                .hide();  //hide the old table
            }

            toBeRemovedTr.appendTo(toTableBody);
        }
    }
    var resetPayCard = function () {
        movePaycard('PrePaidCard', 'AstroPayCard');
        movePaycard('PrePaidCard', 'MoneyMatrix_PayKwik');
        //var toTableBody = $('#payment-methods-wrapper table[data-category="PrePaidCard"] tbody');
        //var toBeRemovedTr = $('#payment-methods-wrapper tr[data-resourcekey$="AstroPayCard"]');
        //if (toTableBody.length > 0 && toBeRemovedTr.length > 0) {
        //    if (toBeRemovedTr.parent().find("tr").length > 1) {
        //        //more than one
        //    } else {
        //        toBeRemovedTr.parents('table')
        //        .hide();  //hide the old table
        //    }

        //    toBeRemovedTr.appendTo(toTableBody);
        //}
    }

    $(document).bind("_ON_PAYMENT_METHOD_LIST_LOAD_", function () { resetPayCard(); });
    resetPayCard();
});
</script>
</ui:MinifiedJavascriptControl>


</asp:Content>

