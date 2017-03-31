<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CM.Web.UI" %>

<script runat="server">
private enum OddsFormat
{
EU = 0,
UK = 1,
US = 3
}

private string GetDataFromCookie(string name)
{
HttpCookie cookie = Request.Cookies[name];
return cookie != null ? cookie.Value : "";
}

public SelectList GetOddsFormat()
{
Type oddsType = typeof(OddsFormat);
Dictionary<string, string> odds = Enum.GetValues(oddsType)
.Cast<int>()
.ToDictionary(o => o.ToString(), o => Enum.GetName(oddsType, o));

return new SelectList(odds, "Key", "Value", GetDataFromCookie("OM_oddsFormat"));
}

public SelectList GetTimeZones(string defaultLabel, string gmtLabel)
{
var zones = new Dictionary<string, string>() { { "", defaultLabel } };
for (int i = -9; i <= 12; i++)
{
string value = new StringBuilder(gmtLabel)
.Append(i > 0 ? "+" : "")
.Append(i != 0 ? i.ToString() : "")
.ToString();
zones.Add(i.ToString(), value);
}
string selection = GetDataFromCookie("EM_timeZone");

return new SelectList(zones, "Key", "Value", selection);
}

public SelectList GetLanguages()
{
LanguageInfo[] languages = SiteManager.Current.GetSupporttedLanguages();
return new SelectList(languages, "LanguageCode", "DisplayName", SiteManager.Current.GetCurrentLanguage().LanguageCode);
}
</script>

<form action="<%= Url.RouteUrl("AccountSettings", new { @action = "Update" }) %>" method="post" id="settingsInput" class="FormList SettingsInputForm">

<fieldset>
<legend class="hidden">
<%= this.GetMetadata(".HEAD_TEXT").SafeHtmlEncode()%>
</legend>
<ul class="FormList SettingsList">
<% if (Settings.Vendor_EnableSports)
{ %>
<li class="FormItem SettingsOddsItem">
<label class="FormLabel" for="settingsOdds"><%= this.GetMetadata(".OddsFormat_Label").SafeHtmlEncode()%></label>
<select id="settingsOdds" class="FormInput" required="required" name="oddsFormat" data-validator="<%= 
ClientValidators.Create().Required(this.GetMetadata(".OddsFormat_Empty")).ToString().SafeHtmlEncode() %>">
<% foreach (SelectListItem item in GetOddsFormat())
{ %>
<option value="<%= item.Value %>" <%= item.Selected ? "selected=\"selected\"" : "" %>><%= this.GetMetadata(".OddsFormatOption_" + item.Text).SafeHtmlEncode()%></option>
<% } %>
</select>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>
<% } %>
<li class="FormItem SettingsZoneItem">
<label class="FormLabel" for="settingsZone"><%= this.GetMetadata(".TimeZone_Label").SafeHtmlEncode()%></label>
<%: Html.DropDownList("timeZone", GetTimeZones(this.GetMetadata(".TimeZone_Default"), this.GetMetadata(".TimeZone_GMT")), new Dictionary<string, object>() 
{ 
{ "class", "FormInput" },
{ "id", "settingsZone" },
})%>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>
<li class="FormItem LangSelectorItem">
<label class="FormLabel" for="langSelector"><%= this.GetMetadata(".Language_Label").SafeHtmlEncode()%></label>
<%: Html.DropDownList("language", GetLanguages(), new Dictionary<string, object>() 
{ 
{ "class", "FormInput" },
{ "id", "langSelector" },
{ "autocomplete", "off" },
})%>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>
</ul>
</fieldset>
<div class="AccountButtonContainer">
<button class="Button AccountButton SubmitRegister" type="submit">
<strong class="ButtonText"><%= this.GetMetadata(".Button_Submit").SafeHtmlEncode() %></strong>
</button>
</div>
</form>

<script type="text/javascript">
    $(function () {
        var LangSelect;
        if (typeof(CMS) !== 'undefined') {
            LangSelect = CMS.mobile360.views.LangSelect;
        } else {
            LangSelect = function (selector, initial) {
                var form = selector.closest('form'),
                    language = initial ? initial : selector.find(':selected').val();

                selector.change(function () {
                    var action = form.attr('action');

                    var index = action.indexOf(language);
                    if (index != -1)
                        action = action.substr(index + language.length);

                    language = $(this).val();
                    form.attr('action', '/' + language + action);
                });

                return {
                    lang: function () { return language; }
                }
            }
        }

        new LangSelect($('#langSelector'));
});
</script>