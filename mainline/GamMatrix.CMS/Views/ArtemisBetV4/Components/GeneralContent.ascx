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

<h1 class="PageTitle"><%=CurrentTitle%></h1>

<div class="PromoSplash">
    <%=CurrentImage.HtmlEncodeSpecialCharactors() %>
</div>

<div class="deposit_link">
    <% if (!Profile.IsAuthenticated) { %>
        <a class="Button CTAButton" href="/Register" title="<%= this.GetMetadata(".RegisterTitle") %>"><%= this.GetMetadata(".Register") %></a>
    <% } else { %>
        <a class="Button CTAButton" href="/Deposit" title="<%= this.GetMetadata(".DepositTitle") %>"><%= this.GetMetadata(".Deposit") %></a>
    <% } %>
</div>

<div class="showPromotionDetail">
    <a href="#" class="PromoDetailLink" title="<%= this.GetMetadata(".DetailTitle") %>"><%= this.GetMetadata(".showPromotionDetail") %></a>
</div>

<div class="PromoTerms" id="pnGeneralLiteral">
    <%= CurrentContent.HtmlEncodeSpecialCharactors()%>
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