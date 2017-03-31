<%@ Page Language="C#" PageTemplate="/InfoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Error,
	   ((string)this.ViewData["ErrorMessage"]).DefaultIfNullOrEmpty(this.GetMetadata(".Message"))) { IsHtml = true }); %>
    <script type="text/javascript">
        (function ($) {
            var cmsViews = CMS.views;

            cmsViews.BackBtn = function (selector) {
                $(selector).click(function () {
                    window.location = '/Withdraw';
                    return false;
                });
            }
        })(jQuery);
    </script>
</asp:Content>

