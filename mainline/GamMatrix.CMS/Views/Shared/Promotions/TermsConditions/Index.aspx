<%@ Page Language="C#" PageTemplate="/Promotions/PromotionsMaster.master" ValidateRequest="false" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<script runat="server" type="text/C#">
    protected string MetadataPath { get { return string.Format("/Metadata/Promotions/{0}/{1}", this.ViewData["actionName"], this.ViewData["parameter"]); } }    
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <% Html.RenderPartial("/Components/GeneralContent", this.ViewData.Merge(new{ @MetadataPath= MetadataPath})); %>
    <script type="text/javascript">
        $(document).ready(function () {
            <%if (!Profile.IsAuthenticated) 
            {%>
                $(".promotions-content-buttons .promotion-button.deposit").remove();
            <%}
            else 
            { %>
                $(".promotions-content-buttons .promotion-button.register").remove();
            <%} %>
        });
    </script>
</asp:Content>

