<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.MenuV2ViewModel>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<script runat="server" type="text/C#">
    public bool IsRestricted(string entryId)
    {
        string result = this.GetMetadata("Metadata/Settings/V2/RestrictedMenuItems." + entryId).Trim().ToLower();
        if (result == "yes" || result == "true")
            return true;
        
        return false;
    }

    public string GetText(string entryId)
    {
        return this.GetMetadata("." + entryId + "_Text").SafeHtmlEncode();
    }
</script>


<% Html.RenderPartial("/Components/AccountPanel", new AccountPanelViewModel()); %>
<div class="MenuData"></div>

<ul class="SideMenuList AccountMenuEntries">
<% foreach(var accountMenuEntry in Model.AccountEntries) {
        if (IsRestricted(accountMenuEntry.EntryId))
            continue;
        %>
        <li class="MenuItem AccountMenuItem Item-<%= accountMenuEntry.CssClass %> X">

            <% if(accountMenuEntry.IsLinkEntry) { %>
                <a class="SideMenuLink MenuLink SMLink-<%= accountMenuEntry.CssClass %>" href="<%= accountMenuEntry.Url %>">
                    <span class="ActionArrow icon-arrow"> </span>
			        <span class="ButtonIcon icon-<%= accountMenuEntry.CssClass %>">&nbsp;</span>
			        <span class="ButtonText"><%= GetText(accountMenuEntry.EntryId) %></span>
                </a>
            <% } else { %>

                <button class="SideMenuLink MenuLink SMLink-<%= accountMenuEntry.CssClass %> LoadPartial" 
                    data-partiallink="<%= Request.IsHttps() ? "https" + "://" + Request.Url.Host  + accountMenuEntry.Url :"http" + "://" + Request.Url.Host + accountMenuEntry.Url %>">
                    <span class="ActionArrow icon-arrow"> </span>
			        <span class="ButtonIcon icon-<%= accountMenuEntry.CssClass %>">&nbsp;</span>
			        <span class="ButtonText"><%= GetText(accountMenuEntry.EntryId) %></span>
                </button>

            <% } %>

        </li>

<% } %>
</ul>

<script>
    $(document).trigger('AccountPanel:update');
</script>