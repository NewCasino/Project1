<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.GetTransInfoRequest>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<script language="C#" type="text/C#" runat="server">
    private string GetMessage()
    {
        string accountName = this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", this.Model.TransData.DebitPayItemVendorID.ToString()));
        string format = this.GetMetadata(".Message");

        return string.Format(format
            , this.Model.TransData.DebitRealAmount
            , this.Model.TransData.DebitRealCurrency
            , accountName
            );
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
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnPendingWithdrawal">

    <center>
        <br />
        <%: Html.SuccessMessage(GetMessage()) %>
    </center>
</ui:Panel>

</div>

<script language="javascript" type="text/javascript">
    $('body').addClass('WithdrawPage');
    $(window).load(function () {
        $(document).trigger("BALANCE_UPDATED");
    });
</script>


</asp:Content>

