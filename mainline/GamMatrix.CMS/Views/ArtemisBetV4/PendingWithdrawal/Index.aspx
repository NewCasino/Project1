<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<List<GamMatrixAPI.TransInfoRec>>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>

<script language="C#" type="text/C#" runat="server">
    private string GetAccountName(TransInfoRec trans)
    {
        return string.Format(this.GetMetadata(".FromAccount")
           , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", trans.DebitPayItemVendorID.ToString()))
           );
    }

    private string GetStatusHtml(TransInfoRec trans)
    {
        return string.Format("<span>{0}</span>"
            , this.GetMetadata(string.Format(".Status_{0}", trans.TransStatus.ToString())).SafeHtmlEncode()
            );
    }

    private bool IsRollbackButtonVisible(TransInfoRec trans)
    {
        if (trans.TransStatus == TransStatus.Pending &&
            trans.TransType == TransType.Withdraw)
        {
            if (Settings.PendingWithdrawal_EnableApprovement)
                return !trans.ApprovalStatus;

            return trans.CreditPayItemVendorID != VendorID.PaymentTrust
                   && trans.CreditPayItemVendorID != VendorID.PayPoint
                   && trans.CreditPayItemVendorID != VendorID.Envoy
                   && trans.CreditPayItemVendorID != VendorID.Bank
                   && trans.DebitPayItemVendorID != VendorID.PaymentTrust
                   && trans.DebitPayItemVendorID != VendorID.PayPoint
                   && trans.DebitPayItemVendorID != VendorID.Envoy
                   && trans.DebitPayItemVendorID != VendorID.Bank;
        }
        return false;
    }
    private string GetTimeForJavaScript(DateTime dateTime)
    {
        return string.Format("\"Year\":{0}, \"Month\":{1}, \"Day\":{2}, \"Hour\":{3}, \"Minute\":{4}, \"Second\":{5}",
            dateTime.Year,
            dateTime.Month,
            dateTime.Day,
            dateTime.Hour,
            dateTime.Minute,
            dateTime.Second).SafeHtmlEncode();
    }
</script>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">

</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="Breadcrumbs" role="navigation">
        <ul class="BreadMenu Container" role="menu">
            <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
                </a>
            </li>
            <li class="BreadItem BreadCurrent" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/PendingWithdrawal/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/PendingWithdrawal/.Name") %></span>
                </a>
            </li>
        </ul>
    </div>

<div id="pending-withdrawal-wrapper" class="content-wrapper">
<h1 id="ProfileTitle" class="ProfileTitle"> <%: this.GetMetadata(".HEAD_TEXT") %> </h1>
<ui:Panel runat="server" ID="pnPendingWithdrawal">
    <%: Html.InformationMessage( this.GetMetadata(".Message") , true ) %>
<div class="transaction-table" id="PendingWithdrawList">
    <div class="holder-flex-100 tableHead">
            <div class="col-15"><span><%= this.GetMetadata(".ListHeader_TransactionID").SafeHtmlEncode()%></span></div>
            <div class="col-20"><span><%= this.GetMetadata(".ListHeader_Date").SafeHtmlEncode()%></span></div>
            <div class="col-10"><span><%= this.GetMetadata(".ListHeader_Account").SafeHtmlEncode()%></span></div>
            <div class="col-10"><span><%= this.GetMetadata(".ListHeader_Amount").SafeHtmlEncode()%></span></div>
            <div class="col-15"><span><%= this.GetMetadata(".ListHeader_Description").SafeHtmlEncode()%></span></div>
            <div class="col-10"><span><%= this.GetMetadata(".ListHeader_Status").SafeHtmlEncode()%></span></div>
            <div class="col-20"></div>
    </div>
<% 
    bool isAlternate = true;
    foreach (TransInfoRec trans in this.Model)
    {
        isAlternate = !isAlternate; %>
        <div class="holder-flex-100 <%= isAlternate ? "odd" : "" %> <%= trans.TransStatus.ToString().ToLowerInvariant() %>">
            <div class="col-15"><span><%= trans.TransID.ToString() %></span></div>
            <div class="col-20" date-time="<%= GetTimeForJavaScript(trans.TransCreated) %>"><span><%= trans.TransCreated.ToString("dd/MM/yyyy HH:mm")%></span></div>
            <div class="col-10"><span><%= GetAccountName(trans).SafeHtmlEncode() %></span></div>
            <div class="col-10"><span><%= MoneyHelper.FormatWithCurrency( trans.DebitRealCurrency, trans.DebitRealAmount) %></span></div>
            <div class="col-15"><span><%= trans.CreditPayItemName %></span></div>
            <div class="col-10">
                <%= GetStatusHtml(trans) %>
            </div>
            <div class="col-20">
                <% if (this.IsRollbackButtonVisible(trans))
                   { %>
                        <%: Html.Button(this.GetMetadata(".Button_Rollback"), new
                        {
                            @onclick = string.Format("self.location='{0}';return false;"
                                , this.Url.RouteUrl("PendingWithdrawal", new { @sid = trans.Sid, @action = "Rollback" }).SafeJavascriptStringEncode()
                                )
                        })%>
                <% } %>
            </div>
        </div>
<%  } %>

</div>



</ui:Panel>
</div>
<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
  function onTransactionsLoad() {
        var t = $("#pending-withdrawal-wrapper .transaction-table");
        $.each(t.find("td.col-time"), function (i, n) {
            var t = $(n);
            var s = t.data("time") || t.attr("date-time");
            var dateJson = $.parseJSON('{' + s + '}');
            var d = new Date(dateJson.Year, dateJson.Month - 1, dateJson.Day, dateJson.Hour, dateJson.Minute, dateJson.Second);
            d = d.convertUTCTimeToLocalTime(d);
            var s = d.format("dd/mm/yyyy hh:nn");
            t.find("span").html(d.format("dd/mm/yyyy hh:nn"));
        });
    }

    $(function () {
        onTransactionsLoad();
    });
jQuery('body').addClass('WithdrawPage');
jQuery('.inner').addClass('ProfileContent WithdrawPage');
jQuery('.MainProfile').addClass('MainWithdraw');
jQuery('.sidemenu li').addClass('PMenuItem');
jQuery('.sidemenu li span').addClass('PMenuLinkContainer');
jQuery('.sidemenu li span a').addClass('ProfileMenuLinks');

setTimeout(function(){
jQuery('.ProfileContent').prepend(jQuery('#ProfileTitle'));
},1);
</script>
</ui:MinifiedJavascriptControl>

</asp:Content>

