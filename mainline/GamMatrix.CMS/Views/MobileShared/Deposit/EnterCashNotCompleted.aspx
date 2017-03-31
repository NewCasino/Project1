<%@ Page Language="C#" PageTemplate="/InfoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="Finance" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, 
	    this.GetMetadata(".Message"))
	    { IsHtml = true }); %>
    <button type="submit" class="Button RegLink DepLink NextStepLink" onclick="window.location.reload()">
		<span class="ButtonText"><%= this.GetMetadata(".Button_Finish").SafeHtmlEncode()%></span>
	</button>
<script type="text/javascript">
    (function ($) {
        var cmsViews = CMS.views;

        cmsViews.BackBtn = function (selector) {
            $(selector).click(function () {
                window.location = '/Deposit';
                return false;
            });
        }
    })(jQuery);

    $(CMS.mobile360.Generic.init);
</script>
</asp:Content>

