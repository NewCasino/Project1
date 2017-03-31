<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.AddApplicationViewModel>" %>

<script runat="server">
	private string GetFormattedIOSUrl()
	{
		if (Model.NativeAppUrl.StartsWith("itms-services"))
			return Model.NativeAppUrl;
		return string.Format("itms-services://?action=download-manifest&amp;;;;url={0}", Model.NativeAppUrl);
	}
</script>

<%
	if (Model.EnableIOS)
	{
		if (!string.IsNullOrWhiteSpace(Model.NativeAppUrl))
		{ %>
<div class="CTABox Container">
	<div class="AppIcon App_IOS"></div>
	<a id="iosDownload" class="Button AppDownload" href="<%= GetFormattedIOSUrl().SafeHtmlEncode() %>">
		<strong class="RegText"><%= this.GetMetadata(".AppDownload").SafeHtmlEncode()%></strong>
	</a>
</div>
		<% }
		else if (Model.ShowAddToHome)
		{%>
<div class="AddToHome Context_IOS">
	<a class="ATHClose" href="#">Close</a>
	<h3 class="ATHTitle"><%= this.GetMetadata(".AppleATH_Title").SafeHtmlEncode()%></h3>
	<%= this.GetMetadata(".AppleATH_Description").HtmlEncodeSpecialCharactors()%>
</div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl2" runat="server" Enabled="true" AppendToPageEnd="false">
<script type="text/javascript">
	$(function () {
		var session = new CMS.utils.StorageWrapper(window.sessionStorage);
		function closeATH() {
			$('.AddToHome').addClass('Hidden');
		}

		if (session.getItem('M360_ATH'))
			closeATH();

		if (window.navigator.standalone) {
			closeATH();

			var expire = new Date();
			expire.setDate(expire.getDate() + 360);

			document.cookie = 'M360_ATH=true' + 
				';expires=' + expire.toUTCString() + 
				';domain=<%= SiteManager.Current.SessionCookieDomain %>';
		}

		$('.ATHClose').click(function () {
			closeATH();
			session.setItem('M360_ATH', true);
		});
	});
</script>
</ui:MinifiedJavascriptControl>
<%		}
	}
	if (Model.EnableAndroid && !string.IsNullOrWhiteSpace(Model.NativeAppUrl))
	{
%>
<div class="CTABox Container">
	<div class="AppIcon App_Android"></div>
	<a class="Button AppDownload" href="<%= Model.NativeAppUrl.SafeHtmlEncode()%>">
		<strong class="RegText"><%= this.GetMetadata(".AppDownload").SafeHtmlEncode()%></strong>
	</a>
</div>
<% } %>