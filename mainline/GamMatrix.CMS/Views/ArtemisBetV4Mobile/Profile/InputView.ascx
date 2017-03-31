<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmUser>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components.ProfileInput" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="CM.Web.UI" %>
<script language="C#" type="text/C#" runat="server">
    protected override void OnLoad(EventArgs e)
    { 
        string fTeam = GamMatrixClient.GetUserMetadata("FavoriteTeam");
        FavoriteTeamStr.Value = fTeam;
        base.OnLoad(e);
    }
</script>

<input type="hidden" style="display:none" runat="server" id="FavoriteTeamStr" class="FavoriteTeamHiddenVal" />
<form action="<%= this.Url.RouteUrl("Profile", new { @action = "UpdateProfile" }).SafeHtmlEncode()%>"
    method="post" enctype="application/x-www-form-urlencoded" id="UpdateProfileForm" target="_self" class="GeneralForm UpdateProfileForm">
    
<fieldset>
<legend class="hidden">
<%= this.GetMetadata(".Legend").SafeHtmlEncode() %>
</legend>

<% Html.RenderPartial("/Components/ProfilePersonalInput", new ProfilePersonalInputViewModel(new ProfileInputEditSettings(this.Model))); %>
<% Html.RenderPartial("/Components/ProfileAddressInput", new ProfileAddressInputViewModel(new ProfileInputEditSettings(this.Model))); %>
<% Html.RenderPartial("/Components/ProfileAccountInput", new ProfileAccountInputViewModel(new ProfileInputEditSettings(this.Model))); %>
<% Html.RenderPartial("/Components/ProfileAdditionalInput", new ProfileAdditionalInputViewModel(new ProfileInputEditSettings(this.Model))); %>

<div class="AccountButtonContainer">
<button class="Button AccountButton" type="submit">
<strong class="ButtonText"><%= this.GetMetadata(".Button_Update").SafeHtmlEncode()%></strong>
</button>
</div>
</fieldset>
</form>