<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<div class="DepositWidget">
    <div class="DWBalance">
        <%: Html.CachedPartial("/Head/TotalBalance", this.ViewData.Merge(new { ColumnCount = "3" })) %>            
        <%: Html.CachedPartial("/Head/RefreshBalance", this.ViewData) %>
        <div style="clear:both;"></div>
    </div>
    <div class="DWDeposit">
        <a href="/deposit" class="DepositButton Button"><span class="ButtonText"><%=this.GetMetadata(".Deposit")%></span></a>
    </div>
    <div class="DWHelp">
        <a href="/help" class="HelpButton Button"><span class="ButtonText"><%=this.GetMetadata(".NeedHelp")%></span></a>
    </div>
</div>