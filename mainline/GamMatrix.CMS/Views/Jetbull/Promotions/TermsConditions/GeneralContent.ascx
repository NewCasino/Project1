<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<script runat="server" type="text/C#">
    private string MetadataPath { get { return this.ViewData["MetadataPath"] as string; } }

    protected string CurrentTitle
    {
        get
        {
            if (string.IsNullOrWhiteSpace(MetadataPath)) return string.Empty;
            return this.GetMetadata(MetadataPath + ".Title");
        }
    }
    
    protected string BackgroundImage
    {
        get
        {
            if (string.IsNullOrWhiteSpace(MetadataPath)) return string.Empty;
            return this.GetMetadata(MetadataPath + ".BackgroundImage").SafeHtmlEncode();
        }
    }
    
    protected string CurrentContent
    {
        get
        {
            if (string.IsNullOrWhiteSpace(MetadataPath)) return string.Empty;
            return this.GetMetadata(MetadataPath + ".Html");
        }
    }
</script>
<div class="promotion-detail">
    <%= CurrentContent.HtmlEncodeSpecialCharactors()%>
    <script type="text/javascript">
        $(document).ready(function () {
            <%if (!string.IsNullOrEmpty(BackgroundImage)) 
            {%>
                $('html body').css('background','url(<%=BackgroundImage %>) no-repeat center top / 100% auto #222');
            <%}%>
        });
    </script>
</div>
