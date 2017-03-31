<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Promotions.Home.ContentListViewModel>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<ol class="MenuList L">
<%
    if (this.Model.NoData)
	{
		Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata(".No_Promo")) { IsHtml = true }); 
	}
	else
    {
        foreach (string path in this.Model.ContentPaths)
        {
%>
        <li class="MenuItem X PromoItem">
			<a href="#" class="MenuLink A Container ToggleButton"> <span class="Page I">Logo</span> <span class="UserInfo"> <span class="PromoItemTitle"><%=this.Model.GetPromoTitle(path).SafeHtmlEncode()%></span> <span class="PromoItemClick"><%=this.GetMetadata(".ClickForDetails").HtmlEncodeSpecialCharactors()%></span> </span> <span class="ToggleArrow">+</span> </a>
			<div class="ToggleContent" style="display: none;">
				<div class="Container PromoContent">
					<%= this.Model.GetPromoSummary(path).HtmlEncodeSpecialCharactors()%>
					<div class="AccountButtonContainer">
						<a href="<%=this.Model.GetTermsUrl(path) %>" class="Button AccountButton"> <strong class="ButtonText"><%= this.GetMetadata(".ButtonText").HtmlEncodeSpecialCharactors()%></strong> </a>
					</div>
				</div>
				<a href="#" class="MoreLink M ToggleClose"> <span class="MW"> <span class="MoreText"><%=this.GetMetadata(".CloseDetails").SafeHtmlEncode()%></span> <span class="CloseArrow">▴</span> </span> </a>
			</div>
		</li>   
<%
        }
    }
%>
</ol>

<script type="text/javascript">
    function ContentList() {

        $('.ToggleButton').click(function () {
            var _this = $(this);
            var content = _this.siblings('.ToggleContent');
            var close = !(content.css('display') == 'none');

            if (close) 
                content.hide();
            else
            	content.show();

            _this.find('.ToggleArrow').html(close ? '+' : '&ndash;');
        });

        $('.ToggleClose').click(function () {
            //queryBack($(this), '.ToggleButton').click();
            $(this).parent().siblings('.ToggleButton').click();
        });

    }

    $(function () {
        new ContentList();
    });
</script>