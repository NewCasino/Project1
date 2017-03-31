<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<script language="C#" type="text/C#" runat="server">
    private string MetadataPath { get { return this.ViewData["MetadataPath"] as string; } }
    private string ClassName { get { return this.ViewData["ClassName"] as string; } }
</script>
<div class="vender-item <%=ClassName %>">
    <div class="vender-item-title">
        <span class="span-title"><%=this.GetMetadata(string.Format("{0}.Title", MetadataPath)).SafeHtmlEncode() %></span></div>
    <div class="vender-item-body">
        <%=this.GetMetadata(string.Format("{0}.Body", MetadataPath)).HtmlEncodeSpecialCharactors()%>
    </div>
    <div class="vender-item-more">
        <%=this.GetMetadata(string.Format("{0}.More", MetadataPath)).HtmlEncodeSpecialCharactors()%>
    </div>
</div>
