<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<div class="Footer">
	<div class="CopyContainer"><%= this.GetMetadata("/Metadata/Footer/.Copyright").HtmlEncodeSpecialCharactors()%></div>
</div>