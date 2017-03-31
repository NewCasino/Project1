<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<script runat="server"> 
    private void Page_Load(object sender, System.EventArgs e) {   
        if (string.Equals(this.ViewData["actionName"].ToString(), "contactus", StringComparison.InvariantCultureIgnoreCase)){
	        Response.Status = "301 Moved Permanently"; 
	        Response.AddHeader("Location","/contactus");     		
    	}
    } 
</script>
<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>
<asp:content contentplaceholderid="cphMain" runat="Server">
<% Html.RenderPartial("/Components/ListContent", this.ViewData.Merge(new { @SideMenuTitle = this.GetMetadata(".SideMenuTitle"), @MetadataPath = "/Metadata/AboutUs", @Category = this.ViewData["actionName"], @SubCategory = this.ViewData["parameter"] })); %>
</asp:content>

