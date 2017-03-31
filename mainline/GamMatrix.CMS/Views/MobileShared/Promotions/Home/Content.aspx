<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Promotions.Home" %>

<script type="text/C#" runat="server">
	private string Category
	{
		get
		{
			return this.ViewData["Category"] as string ?? string.Empty;
		}
	}

	private string SubCategory
	{
		get
		{
			return this.ViewData["SubCategory"] as string ?? string.Empty;
		}
	}

    private string GetContentMetaPath()
    {
		return string.Format("/Metadata/Promotions/{0}{1}",
			Category,
			string.IsNullOrEmpty(SubCategory) ? "" : "/" + SubCategory
		);
    }

	protected override void OnInit(EventArgs e)
	{
		string pageTitle = this.GetMetadata(".Title");
		if (!string.IsNullOrEmpty(PageTemplate))
		{
			Page.Title = pageTitle.Replace("$CATEGORY$", Category);
		}
		base.OnInit(e);
	}
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="Box">
		<div class="BoxContent">
			<% Html.RenderPartial("ContentsList", new ContentListViewModel(GetContentMetaPath())); %>
		</div>
	</div>
	<script type="text/javascript">
		$(CMS.mobile360.Generic.init);
	</script>	
</asp:Content>

