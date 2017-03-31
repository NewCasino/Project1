<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<%: Html.H1(this.GetMetadata(".MenuTitle")) %>

<ui:Panel runat="server" ID="pnSideMenu" CssClass="sidemenupanel">
<% Html.RenderPartial("/Components/SideMenu", this.ViewData.Merge(new { @MetadataPath = "/Metadata/ProfileMenu" })); %>
</ui:Panel>