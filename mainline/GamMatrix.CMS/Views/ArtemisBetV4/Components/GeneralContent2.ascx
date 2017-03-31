<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<script runat="server" type="text/C#">
    private string MetadataPath { get { return this.ViewData["MetadataPath"] as string; } }
    
    protected string CurrentTitle {
    get {
            if (string.IsNullOrWhiteSpace(MetadataPath)) return string.Empty;
            return this.GetMetadata(MetadataPath+".Title");
        }
    }
    protected string CurrentContent {
        get {
            if (string.IsNullOrWhiteSpace(MetadataPath)) return string.Empty;
            return this.GetMetadata(MetadataPath+".Html");
        }
    }
    protected string CurrentImage {
        get {
            if (string.IsNullOrWhiteSpace(MetadataPath)) return string.Empty;
            return this.GetMetadata(MetadataPath+".Image");
        }
    }
</script>

<div class="ResponsibleGamingContainer">

    <h1 class="PageTitle"><%=CurrentTitle%></h1>
    
    <div class="ResponsibleGamingSplash">
        <%= CurrentContent.HtmlEncodeSpecialCharactors()%>
    </div>

</div>

<ui:MinifiedJavascriptControl runat="server">
    <script type="text/javascript">
        $(document).ready(function(){
            $("#pnGeneralLiteral").hide();
            $(".showPromotionDetail").click(function(){
                $("#pnGeneralLiteral").show(500);
                $(".showPromotionDetail").hide(500);
            });
        });
    </script>
</ui:MinifiedJavascriptControl>