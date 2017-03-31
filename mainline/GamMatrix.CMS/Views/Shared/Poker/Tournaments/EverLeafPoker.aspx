<%@ Page Language="C#" PageTemplate="/Poker/PokerMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="everleaf-tournament-list" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnEverLeafPokerTournamentList">

<% this.Html.RenderAction("EverLeafPokerTournamentList"); %>

</ui:Panel>
</div>

</asp:Content>

