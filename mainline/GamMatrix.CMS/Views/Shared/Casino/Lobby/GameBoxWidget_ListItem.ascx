<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CasinoEngine.Game>" %>
<%@ Import Namespace="CasinoEngine" %>



<li class="GLItem" data-gameID="<%= this.Model.ID %>" data-backgroundImage="<%= this.Model.BackgroundImageUrl.SafeHtmlEncode() %>" data-isAnonymousFunModeEnabled="<%=this.Model.IsAnonymousFunModeEnabled? "1" : "0" %>">
	<div class="GameThumb">
		<ul class="GTPopup">

            <% if (this.Model.IsRealMoneyModeEnabled)
               { %>
			<li class="GTPItem PlayNow">
				<a href="/Casino/Game/Index/<%= this.Model.Slug.DefaultIfNullOrEmpty(this.Model.ID).SafeHtmlEncode() %>?realMoney=True" class="GTPLink BtnPlayReal" title="<%= this.GetMetadataEx(".Button_Play_Now_Tip_Format", this.Model.ShortName).SafeHtmlEncode()%>">
                    <span class="ActionIcon Play">&#9658;</span>
                    <%= this.GetMetadata(".Button_Play_Now").SafeHtmlEncode()%>
                </a>
			</li>
            <% } %>

            <% if (this.Model.IsFunModeEnabled)
               { %>
			<li class="GTPItem Play4Fun">
				<a href="/Casino/Game/Index/<%= this.Model.Slug.DefaultIfNullOrEmpty(this.Model.ID).SafeHtmlEncode() %>?realMoney=False" class="GTPLink BtnPlayFun" title="<%= this.GetMetadataEx(".Button_Play_For_Fun_Tip_Format", this.Model.ShortName).SafeHtmlEncode()%>">
                    <span class="ActionIcon Fun">&#9786;</span>
                    <%= this.GetMetadata(".Button_Play_For_Fun").SafeHtmlEncode()%>
                </a>
			</li>
            <% } %>

			<li class="GTPItem Add2Fav">
				<a href="#" class="GTPLink BtnAddFavorite" title="<%= this.GetMetadataEx(".Button_Add_To_Favorites_Tip_Format", this.Model.ShortName).SafeHtmlEncode()%>">
                    <span class="ActionIcon Fav">&#9733;</span> 
                    <%= this.GetMetadata(".Button_Add_To_Favorites").SafeHtmlEncode()%>
                </a>
			</li>

            <li class="GTPItem hidden">
				<a href="#" class="GTPLink BtnRemoveFavorite" title="<%= this.GetMetadataEx(".Button_Remove_From_Favorites_Tip_Format", this.Model.ShortName).SafeHtmlEncode()%>">
                    <span class="ActionIcon Remove">&#9733;</span> 
                    <%= this.GetMetadata(".Button_Remove_From_Favorites").SafeHtmlEncode()%>
                </a>
			</li>
		</ul>
		<img class="GT" data-image="<%= this.Model.ThumbnailUrl.SafeHtmlEncode() %>" src="/images/transparent.gif" width="120" height="70" alt="<%= this.Model.ShortName.SafeHtmlEncode()%>" />
	</div>
	<h3 class="GameTitle">
		<a target="_self" href="javascript:void(0)" class="InfoIcon GameInfo" title="<%= this.Model.Description.SafeHtmlEncode() %>">
            <%= this.GetMetadata(".Info").SafeHtmlEncode() %>
        </a>
		<a  target="_self" href="/Casino/Game/Index/<%= this.Model.Slug.DefaultIfNullOrEmpty(this.Model.ID).SafeHtmlEncode() %>" class="Game" title="<%= this.GetMetadataEx(".Play_Now_Tip_Format", this.Model.ShortName).SafeHtmlEncode()%>">
            <%= this.Model.ShortName.SafeHtmlEncode()%>
        </a>
	</h3>
</li>



