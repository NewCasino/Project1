<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="Finance" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">  

</asp:Content>
<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
  <div class="sitemap">
    <div class="mainPanel">
      <%: Html.H1(this.GetMetadata(".SiteMap_Text")) %>
      <ui:Panel runat="server" ID="pnGeneralLiteral"> <%= this.GetMetadata(".SiteMap_Html")%> </ui:Panel>
    </div>
    <div class="rightPanel">
      <% if (!Profile.IsAuthenticated){%>
      <a href="/register" class="sitemap_regbutton"><%=this.GetMetadata(".SiteMap_Register_Text").DefaultIfNullOrEmpty("Untitled").SafeHtmlEncode()%></a>
      <%}%>
    </div>
  </div>
<%
List<GamMatrixAPI.AccountData> list = GamMatrixClient.GetUserGammingAccounts( Profile.UserID, false);
var accounts = list
                    .Where(a => a.Record.ActiveStatus == GamMatrixAPI.ActiveStatus.Active && a.IsBalanceAvailable)
                    .Select(a => new
                    {
                        AccountID = a.Record.ID.ToString(),
                        VendorID = a.Record.VendorID.ToString(),
                        DisplayName = a.Record.VendorID.GetDisplayName(),
                        BalanceCurrency = a.BalanceCurrency,
                        BalanceAmount = Math.Truncate(a.BalanceAmount * 100.00M) / 100.00M,
                        BonusAmount = a.BonusAmount,



                    }).ToList();


//string [] paths = Metadata.GetChildrenPaths("/Metadata/GammingAccount/");

%>

<br/>

<br/>
<%=accounts.Count%>

</asp:Content>
