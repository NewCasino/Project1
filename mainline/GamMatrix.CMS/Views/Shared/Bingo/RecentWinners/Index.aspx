<%@ Page Language="C#" PageTemplate="/Bingo/BingoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<%Html.RenderPartial("/Bingo/Home/RecentDailyFreePlayWinnersWidget"); %>
</asp:Content>

