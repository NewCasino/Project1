<%@ Page Language="C#" PageTemplate="/Sports/SportsMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<script type="text/C#" runat="server">
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        if (Profile.IsAuthenticated)
        {
            bool IsEmailVerified = Profile.IsEmailVerified;
            if (!Profile.IsEmailVerified)
            {
                CM.db.Accessor.UserAccessor ua = CM.db.Accessor.UserAccessor.CreateInstance<CM.db.Accessor.UserAccessor>();
                CM.db.cmUser user = ua.GetByID(Profile.UserID);
                if (user.IsEmailVerified)
                {
                    IsEmailVerified = true;
                    Profile.IsEmailVerified = true;
                }
            }

            if (IsEmailVerified)
            {
                if (Profile.IsInRole("Incomplete Profile"))
                {
                    Response.Redirect("/IncompleteProfile");
                }
            }
            else
            {
                Response.Redirect("/EmailNotVerified");
            }
        }
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<% Html.RenderPartial( "../Iframe", this.ViewData.Merge( new { ConfigrationItem = "OddsMatrix_HomePage"})); %>

</asp:Content>

