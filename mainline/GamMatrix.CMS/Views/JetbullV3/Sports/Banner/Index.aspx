<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<style type="text/css">
html, body { overflow:hidden; margin:0; padding:0; background-image:none !important; background-color:transparent !important; }
</style>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<%
string path =  "SportsSlider";

        if (!string.IsNullOrEmpty(this.ViewData["actionName"].ToString()) && this.ViewData["actionName"].ToString() != "Index")
            path = this.ViewData["actionName"].ToString();
%>
<!--
<%=path%>
-->
<div class="SportsSlider">
<% Html.RenderPartial("/Components/Slider", this.ViewData.Merge(new { @SliderPath = "/Sports/"+ path +"/" })); %>
</div>

</asp:Content>

