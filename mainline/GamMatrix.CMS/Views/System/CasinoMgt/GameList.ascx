<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Runtime.Serialization.Formatters.Binary" %>
<script language="C#" runat="server" type="text/C#">
private string[] GetGamePaths()
{
    return (string[])this.ViewData["gamePaths"];
}

public string GetInitialWidthHtml(string path)
{
    string initialWidth = Metadata.Get(this.Model, string.Format("{0}.InitialWidth", path), "en");
    if (string.IsNullOrWhiteSpace(initialWidth))
        return string.Empty;

    return string.Format("<li><strong>Initial Width</strong> : {0}px</li>", initialWidth.SafeHtmlEncode());
}

public string GetInitialHeightHtml(string path)
{
    string initialHeight = Metadata.Get(this.Model, string.Format("{0}.InitialHeight", path), "en");
    if (string.IsNullOrWhiteSpace(initialHeight))
        return string.Empty;

    return string.Format("<li><strong>Initial Height</strong> : {0}px</li>", initialHeight.SafeHtmlEncode());
}

public bool IsNewGame(string path)
{
    string isNewGame = Metadata.Get(this.Model, string.Format("{0}.IsNewGame", path), "en");
    if (string.IsNullOrWhiteSpace(isNewGame))
        return false;

    return string.Equals(isNewGame.Trim(), "YES", StringComparison.OrdinalIgnoreCase);
}

public bool IsMiniGame(string path)
{
    string isMiniGame = Metadata.Get(this.Model, string.Format("{0}.IsMiniGame", path), "en");
    if (string.IsNullOrWhiteSpace(isMiniGame))
        return false;

    return string.Equals(isMiniGame.Trim(), "YES", StringComparison.OrdinalIgnoreCase);
}

public bool IsFunModeEnabled(string path)
{
    string isFunModeEnabled = Metadata.Get(this.Model, string.Format("{0}.IsFunModeEnabled", path), "en");
    if (string.IsNullOrWhiteSpace(isFunModeEnabled))
        return true;

    return string.Equals(isFunModeEnabled.Trim(), "YES", StringComparison.OrdinalIgnoreCase);
}

public string GetSupportedCountryHtml(string path)
{
    StringBuilder html = new StringBuilder();
    html.AppendFormat(CultureInfo.InvariantCulture, "<a class=\"lnk-edit-supported-countries\" href=\"javascript:void(0)\" target=\"self\" path=\"{0}\">"
        , path.DefaultEncrypt()
        );
    string base64 = Metadata.Get(this.Model, string.Format("{0}.SupportedCountry", path), "en");

    Finance.CountryList countryList = null;
    try
    {
        using (MemoryStream ms = new MemoryStream(Convert.FromBase64String(base64)))
        {
            BinaryFormatter bf = new BinaryFormatter();
            countryList = (Finance.CountryList)bf.Deserialize(ms);
        }
    }
    catch
    {
        countryList = new Finance.CountryList();
        countryList.Type = Finance.CountryList.FilterType.Exclude;
    }
    html.Append(FormatCountryList(countryList).SafeHtmlEncode());
    
    html.Append("</a>");

    return html.ToString();
}


private string FormatCountryList(Finance.CountryList countryList)
{
    List<CountryInfo> countries = CountryManager.GetAllCountries(this.Model.DistinctName);

    StringBuilder text = new StringBuilder();
    if (countryList.Type == Finance.CountryList.FilterType.Exclude)
    {
        if (countryList.List == null ||
            countryList.List.Count == 0)
        {
            text.Append("All");
        }
        else
        {
            text.Append("Exclude ");
        }
    }
    else
    {
        if (countryList.List == null ||
            countryList.List.Count == 0)
        {
            text.Append("None");
        }
    }

    if (countryList.List != null)
    {
        foreach (int countryID in countryList.List)
        {
            CountryInfo country = countries.FirstOrDefault(c => c.InternalID == countryID);
            if (country != null)
                text.AppendFormat(CultureInfo.InvariantCulture, " {0} ,", country.EnglishName);
        }
        if (text.Length > 0)
            text.Remove(text.Length - 1, 1);
    }
    return text.ToString();
}
</script>


<%
    foreach (string path in GetGamePaths())
    {
        string url = this.Url.RouteUrl( "MetadataEditor", new { @action = "AdvancedEditor", @distinctName = this.Model.DistinctName.DefaultEncrypt(), @path = path.DefaultEncrypt() });     
         %>

    <table cellpadding="5" cellspacing="0" border="0" class="game-table">
        <thead>
            <tr>
                <th colspan="2" align="left">
                    <%= Metadata.Get(this.Model, string.Format("{0}.Title", path), "en").SafeHtmlEncode()%>&nbsp;
                    <a class="dialog-link" href="<%= url.SafeHtmlEncode() %>?id=Title" target="_blank">EDIT...</a>
                </th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td colspan="2" align="left">
                    <%= Metadata.Get(this.Model, string.Format("{0}.Description", path), "en").SafeHtmlEncode()%>
                    <a class="dialog-link" href="<%= url.SafeHtmlEncode() %>?id=Description" target="_blank">EDIT...</a>
                </td>
            </tr>
        </tbody>
        <tfoot>
            <tr>
                <td>
                    <ul>
                        <li><strong>ID</strong> : <%= Metadata.Get(this.Model, string.Format("{0}.ID", path), "en").SafeHtmlEncode()%></li>
                        <li><strong>Vendor</strong> : <%= Metadata.Get(this.Model, string.Format("{0}.Vendor", path), "en").SafeHtmlEncode()%></li>
                        <li><strong>Category</strong> : <%= Metadata.Get(this.Model, string.Format("{0}.Category", path), "en").SafeHtmlEncode()%></li>
                        <%= GetInitialWidthHtml(path) %>
                        <%= GetInitialHeightHtml(path) %>
                        <li><input name="IsNewGame" id="newgame<%=path.GetHashCode() %>" type="checkbox" <%=IsNewGame(path) ? "checked=\"checked\"" : "" %> value="<%= path.DefaultEncrypt() %>" /><label for="newgame<%=path.GetHashCode() %>">New Game</label></li>
                        <li><input name="IsMiniGame" id="minigame<%=path.GetHashCode() %>" type="checkbox" <%=IsMiniGame(path) ? "checked=\"checked\"" : "" %> value="<%= path.DefaultEncrypt() %>" /><label for="minigame<%=path.GetHashCode() %>">Mini Game</label></li>
                        <li><input name="IsFunModeEnabled" id="funmode<%=path.GetHashCode() %>" type="checkbox" <%=IsFunModeEnabled(path) ? "checked=\"checked\"" : "" %> value="<%= path.DefaultEncrypt() %>" /><label for="funmode<%=path.GetHashCode() %>">Enable Fun Mode</label></li>
                        <li><strong>Supported Country(s)</strong> : <%=GetSupportedCountryHtml(path)%></li>
                        <%-- 
                        <li><strong>Additional 3rd Party Vendor Fee</strong> : </li>
                        <li><strong>Invoicing Group</strong> : </li>
                        <li><strong>Theoretical Pay Out</strong> : </li>
                            --%>
                        
                    </ul>
                </td>
                <td align="right" valign="middle">
                    <%= Metadata.Get(this.Model, string.Format("{0}.Thumbnail", path), "en") %><br />
                    <a class="dialog-link" href="<%= url.SafeHtmlEncode() %>?id=Thumbnail" target="_blank">EDIT...</a>
                </td>
            </tr>
        </tfoot>
    </table>

<% } %>


<script language="javascript" type="text/javascript">
    $('a.dialog-link').click(function (e) {
        e.preventDefault();

        $('<div style="display:none"><iframe frameborder="0" class="ifmDialog"></iframe></div>').dialog({
            height: 600,
            width: '90%',
            draggable: false,
            resizable: false,
            modal: true,
            close: function () {
                self.CasinoMgt.tabGames.refresh();
            }
        });
        $('iframe.ifmDialog').attr('src', $(this).attr('href'));
    });

    $('input[name="IsNewGame"][type="checkbox"],input[name="IsMiniGame"][type="checkbox"],input[name="IsFunModeEnabled"][type="checkbox"]').click(function (e) {
        $(this).attr('disabled', true);

        var url = '<%= this.Url.RouteUrl("CasinoMgt", new { @action = "SetFlag", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>?flagValue=';
        if ($(this).is(':checked')) url += 'YES';
        else url += 'NO';
        url += '&path=' + $(this).val();
        url += '&flagName=' + $(this).attr('name');

        var fun = (function (chkbox) {
            return function () {
                var data = arguments[0];
                if (!data.success) { alert(data.error); return; }
                chkbox.attr('disabled', false);
            };
        })($(this));
        jQuery.getJSON(url, null, fun);
    });

    $('a.lnk-edit-supported-countries').click(function (e) {
        e.preventDefault();
        var url = '<%= this.Url.RouteUrl( "CasinoMgt", new { @action = "SupportedCountry", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode()%>?path=';
        url += $(this).attr('path');
        $('<div class="popup-dialog"><img src="/images/icon/loading.gif" /></div>').appendTo(document.body).load(url).dialog({
            autoOpen: true,
            height: 'auto',
            minHeight: 50,
            position: [100, 50],
            width: 700,
            modal: true,
            resizable: false,
            close: function (ev, ui) { $("div.popup-dialog").dialog('destroy'); $("div.popup-dialog").remove(); }
        });
    });

</script>