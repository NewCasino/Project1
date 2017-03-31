<%@ Page Language="C#" PageTemplate="/Promotions/PromotionsMaster.master" ValidateRequest="false" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<script runat="server" type="text/C#">
    protected string MetadataPath { get { return string.Format("/Metadata/Promotions/{0}/{1}", this.ViewData["actionName"], this.ViewData["parameter"]); } }    
    
    protected override void OnInit(EventArgs e)
    {
        this.Page.Title = this.GetMetadata(MetadataPath + ".Title");
        base.OnInit(e);
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <% Html.RenderPartial("/Promotions/TermsConditions/GeneralContent", this.ViewData.Merge(new{ @MetadataPath= MetadataPath})); %>
    <script type="text/javascript">
        $(function() {
            $('body').addClass('promtions_<%=this.ViewData["actionName"] %>_<%=this.ViewData["parameter"] %>');
            <% if (Profile.IsAuthenticated) {%>
                $(".promotion-detail .button-register").remove();
            <%}
            else 
            {%>
                $(".promotion-detail .button-deposit").remove();
            <%} %>
        });
    </script>
</asp:Content>

