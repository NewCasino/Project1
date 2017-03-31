<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<% Html.RenderPartial("/Components/HeaderView", new HeaderViewModel { 
	IsLocalSite = this.ViewData["IsLocalSite"] as bool? ?? false, 
	DisableAccount = this.ViewData["DisableAccount"] as bool? ?? false 
}); %>