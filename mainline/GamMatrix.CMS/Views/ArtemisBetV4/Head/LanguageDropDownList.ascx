<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<script language="C#" runat="server" type="text/C#">
    private string GetUrlWithLanguage(string lang)
    {
        return string.Format( "/{0}/{1}", lang, this.Request.Url.PathAndQuery.TrimStart('/'));
    }

    private string DisplayModel {
        get { return this.ViewData["DisplayModel"] as string; }
    }
</script><%
    LanguageInfo[] languages = SiteManager.Current.GetSupporttedLanguages();
    LanguageInfo currentLanguage = languages.FirstOrDefault(l => 
        string.Equals(l.LanguageCode, HttpContext.Current.GetLanguage(), StringComparison.OrdinalIgnoreCase)
    );
 %>

<a href="javascript:void(0);" id="language-drop-down-list" class="LanguageToggle">
<% if (currentLanguage != null) { %>
    <span class="LanguageSymbol <%= currentLanguage.CountryFlagName.SafeHtmlEncode() %>" title="<%= currentLanguage.DisplayName.SafeHtmlEncode() %>"><%= currentLanguage.DisplayName.SafeHtmlEncode() %></span>
    <span class="LanguageName"><%= currentLanguage.CountryFlagName.SafeHtmlEncode() %></span>
<% } %>
</a>

<ul id="language-list" class="LanguageList" style="display:none">
<% foreach (LanguageInfo lang in languages) {
            if (lang != currentLanguage) {
%>
    <li class="LanguageItem">
        <a class="LanguageLink" href="<%= GetUrlWithLanguage(lang.LanguageCode).SafeHtmlEncode() %>" title="<%= lang.DisplayName.SafeHtmlEncode() %>">
            <span class="LanguageSymbol <%= lang.CountryFlagName.SafeHtmlEncode() %>"><%= lang.DisplayName.SafeHtmlEncode() %></span>
            <span class="LanguageName"><%= lang.CountryFlagName.SafeHtmlEncode() %></span>
        </a>
    </li>
<% } } %>
</ul>

<ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
<script language="javascript" type="text/javascript">
    function displayLanguageOptions() {
        $('#language-list').detach().appendTo(document.body);
        $('#language-list').css({
            position:'absolute',
            left: $('#language-drop-down-list').offset().left.toString(10) + 'px',
            top:($('#language-drop-down-list').offset().top + $('#language-drop-down-list').height()).toString(10) + 'px',
            width: $('#language-drop-down-list').width()-1  + 'px'
        }).fadeIn('fast');
    }
    $(window).resize(function() {
        $('#language-list').hide();
    });    
    $(document).ready(function () {
        <% if(!string.IsNullOrEmpty(DisplayModel) && DisplayModel.Equals("mouseenter",StringComparison.OrdinalIgnoreCase)){ %>
            $('#language-drop-down-list').mouseover(function (e) {
                displayLanguageOptions();
                return false;
            });
            $("#language-list").mouseover(function () {
                return false;
            });
            $(document.body).mouseover(function () {
                $('#language-list').hide();
            });
        <% } else { %>
            $('#language-drop-down-list').click(function (e) {
                displayLanguageOptions();
            });        
        <% } %>           
        $(document.body).mouseup(function () {
            $('#language-list').hide();
        });     
    });    
</script>
</ui:MinifiedJavascriptControl>