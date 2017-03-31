<%@ Page Language="C#" PageTemplate="/Sports/SportsMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<%
    string st = string.Equals(MultilingualMgr.GetCurrentCulture().ToLowerInvariant(), 
                "zh-cn", 
                StringComparison.InvariantCultureIgnoreCase
                ) ? "OddsMatrix_AsianSports" : "OddsMatrix_HomePage";
    Html.RenderPartial( "../Iframe", this.ViewData.Merge( new { ConfigrationItem = st })); 
    
    %>

    <script type="text/javascript">
        $(function () {
            $(document.body).addClass("sportsbook");
        })
    </script>
</asp:Content>

