<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="CasinoEngine" %>

<script type="text/C#" runat="server">

private sealed class PromotionEntry
{
    public string Title { get; set; }
    public string BackgroundImageUrl { get; set; }
    public string Description { get; set; }
    public string Url { get; set; }
}

/// <summary>
/// Get the games for the slider
/// </summary>
/// <returns></returns>
private List<PromotionEntry> GetPromotions()
{
    List<PromotionEntry> promotions = new List<PromotionEntry>();
        
    string [] paths = Metadata.GetChildrenPaths( (this.ViewData["Path"] as string).DefaultIfNullOrEmpty("/Casino/PromotionList") );
    foreach (string path in paths)
    {
        string url = Metadata.Get(path + ".Url");
        string title = Metadata.Get(path + ".Title");
        string description = Metadata.Get(path + ".Description");
        string backgroundImage = Metadata.Get(path + ".BackgroundImage");

        PromotionEntry promotion = new PromotionEntry()
        {
            Title = title,
            Description = description,
            Url = url,
        };

        if (!string.IsNullOrWhiteSpace(backgroundImage))
        {
            string backgroundImageUrl = ContentHelper.ParseFirstImageSrc(backgroundImage);
            if (!string.IsNullOrWhiteSpace(backgroundImageUrl))
                promotion.BackgroundImageUrl = backgroundImageUrl;
            else
                promotion.BackgroundImageUrl = backgroundImage;
        }

        promotions.Add(promotion);
    }

    return promotions;
}
</script>

<% string wrapperID = Guid.NewGuid().ToString("N"); %>
<div class="Box TopPromo" id="<%= wrapperID %>">
	<h2 class="BoxTitle TopPromoTitle">
		<span class="TitleIcon">&sect;</span>
<% 
    string allPromotionsPageUrl = (this.ViewData["allPromotionsPageUrl"] as string);
    if( !string.IsNullOrWhiteSpace(allPromotionsPageUrl) )
    { %>
		<a href="<%= allPromotionsPageUrl.SafeHtmlEncode() %>" class="TitleLink" title="<%= this.GetMetadata(".All_Promotions_Link_Tip").SafeHtmlEncode()%>">
            <%= this.GetMetadata(".All_Promotions_Link").SafeHtmlEncode()%>
            <span class="ActionSymbol">&#9658;</span>
        </a>
<%  } %>
		<strong class="TitleText"><%= this.GetMetadata(".Title").SafeHtmlEncode() %></strong>
	</h2>
    <div class="PromotionsContainer Canvas">
        <ol class="PromotionsList Container">        
<%
    List<PromotionEntry> promotions = GetPromotions();
    foreach( PromotionEntry promotion in promotions )
    { %>
        <li class="PromotionItem">
        <a href="<%= promotion.Url.SafeHtmlEncode() %>" class="Promotion" 
            style="background-image:url(<%= promotion.BackgroundImageUrl.SafeHtmlEncode() %>)">
		    <h3 class="PromoTitle">
			    <strong class="PTImportant"><%= promotion.Title.SafeHtmlEncode().DefaultIfNullOrEmpty("&#160;")%></strong>
			    <span class="PTP">&#160;</span>
			    <span class="PTP"><%= promotion.Description.SafeHtmlEncode().DefaultIfNullOrEmpty("&#160;") %></span>
		    </h3>
	    </a>
        </li>
<%    } %>
    </ol>
    </div>
	
</div>

<script type="text/javascript">
    $(function () {
        var $wrapper = $('#<%= wrapperID %>');

        function startAnimation() {
            var $container = $('ol.PromotionsList', $wrapper);
            var $li = $('li:first', $container);
            $li.animate({ 'marginTop': -1 * $li.outerHeight() }
                , {
                    duration: 500,
                    easing: 'linear',
                    complete: function () {
                        $li.css('marginTop', 0).detach().appendTo($container);
                        setTimeout(startAnimation, 2000);
                    }
                });
        }
        if ($wrapper.find("li.PromotionItem").length > 1)
            startAnimation();
    });
</script>  
