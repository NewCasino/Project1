<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<GamMatrix.CMS.Models.MobileShared.LiveCasino.LiveTableCategory>>" %>
<%@ Import Namespace="CasinoEngine" %>
<script runat="server">
	private List<GamMatrix.CMS.Models.MobileShared.LiveCasino.LiveTable> GetLiveTales()
	{
        if (!Settings.Vendor_EnableLiveCasino)
            return null;

        List<GamMatrix.CMS.Models.MobileShared.LiveCasino.LiveTable> list = new List<GamMatrix.CMS.Models.MobileShared.LiveCasino.LiveTable>();
        bool visibleOnSmallDevice = false;
        foreach (var category in Model)
        {
            visibleOnSmallDevice = false;
            if (category.Name.Equals("Roulette", StringComparison.InvariantCultureIgnoreCase))
                visibleOnSmallDevice = true;
            
            foreach (var table in category.Tables)
            { 
                if(!list.Exists(t=>t.ID.Equals(table.ID, StringComparison.InvariantCultureIgnoreCase)))
                {
                    table.VisibleOnSmallDevice = visibleOnSmallDevice;
                    list.Add(table);
                }
                else
                {
                    list.FirstOrDefault(t => t.ID.Equals(table.ID, StringComparison.InvariantCultureIgnoreCase)).VisibleOnSmallDevice = visibleOnSmallDevice;
                }
            }            
        }

        return list;
	}
</script>

<% 
    var liveTablesList = GetLiveTales();
    if (liveTablesList.Count != 0)
    { 
%>

<div class="Box TableCategory Category_LiveCasino LiveCasinoSection">
	<h2 class="TableCatTitle">
		<a class="TableCatLink" href="#">
			<span class="ToggleIcon"><span class="ToggleText"><%= this.GetMetadata(".Toggle").SafeHtmlEncode()%></span></span>
			<span class="CatIcon"><span class="CatIconText"><%= this.GetMetadata(".Icon_Category").SafeHtmlEncode()%></span></span>
			<span class="TableCatText"><%= this.GetMetadata(".Category_Name").SafeHtmlEncode()%></span>
		</a>
	</h2>
	<%	Html.RenderPartial("LiveTableDisplay", liveTablesList);%>
</div>

<% 
    } 
%>
