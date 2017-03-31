<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<script runat="server" type="text/C#">
    private string MetadataPath { get { return this.ViewData["MetadataPath"] as string; } }
    
    protected string CurrentTitle {
        get {
            if (string.IsNullOrWhiteSpace(MetadataPath)) return string.Empty;
            return this.GetMetadata(MetadataPath+".Title");
        }
    }
    protected string CurrentContent
    {
        get
        {
            if (string.IsNullOrWhiteSpace(MetadataPath)) return string.Empty;
            return this.GetMetadata(MetadataPath+".Html");
        }
    }
</script>

<%: Html.H1(CurrentTitle) %>
<ui:Panel runat="server" ID="pnGeneralLiteral">
<%= CurrentContent.HtmlEncodeSpecialCharactors()%>
</ui:Panel>