<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<script language="C#" runat="server" type="text/C#">
    private string GetUrlWithLanguage(string lang)
    {
        return string.Format( "/{0}/{1}", lang, this.Request.Url.PathAndQuery.TrimStart('/'));
    }
</script>

<div id="language-selector" class="country-flags">
    <%
        LanguageInfo[] languages = SiteManager.Current.GetSupporttedLanguages();
        for (int i = 0; i < languages.Length; i++)
        {
            LanguageInfo language = languages[i];
            bool isSelected = string.Equals(language.LanguageCode, MultilingualMgr.GetCurrentCulture());
            
    %>
    <div class="item <%= (i==0) ? "first" : ((i==languages.Length-1) ? "last" : "") %> <%= isSelected ? "selected" : "" %>">
        <a href="<%= this.GetUrlWithLanguage(language.LanguageCode) %>" target="_top" title="<%= language.DisplayName.SafeHtmlEncode() %>">
            <img alt="<%= language.DisplayName.SafeHtmlEncode() %>" src="//cdn.everymatrix.com/images/transparent.gif"
                class="<%= language.CountryFlagName.SafeHtmlEncode() %>" />
            <span class="text"><%= language.DisplayName.SafeHtmlEncode() %></span>
        </a>
    </div>
    <%
        }
    %>
</div>
