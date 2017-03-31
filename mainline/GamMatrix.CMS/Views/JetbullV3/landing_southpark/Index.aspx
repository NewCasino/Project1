<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server"><div class="landing_banner">
<div class="landing_banner_content"><%= this.GetMetadata(".landing_banner") %></div>
</div>
<%= this.GetMetadata(".landing_steps") %>
<div class="clear"></div>
<div class="aboutus_box">
<div class="aboutus_icon"><%= this.GetMetadata(".aboutus_icon") %></div>
<div class="aboutus_content"><%= this.GetMetadata(".aboutus_content") %></div>
<div class="clear"></div>
</div></asp:Content>

