<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<script language="C#" runat="server" type="text/C#">
    private string GetUrlWithLanguage(string lang)
    {
        return string.Format( "/{0}/{1}", lang, this.Request.Url.PathAndQuery.TrimStart('/'));
    }

    private string DisplayModel {
        get { return this.ViewData["DisplayModel"] as string; }
    }

    private bool ShowNameForCurrentLanguage
    {
        get
        {
            bool _ShowNameForCurrentLanguage = false;
            if (this.ViewData["ShowNameForCurrentLanguage"]!=null) 
                bool.TryParse(this.ViewData["ShowNameForCurrentLanguage"].ToString(), out _ShowNameForCurrentLanguage);

            return _ShowNameForCurrentLanguage;
        }
    }
</script>

<%
    LanguageInfo[] languages = SiteManager.Current.GetSupporttedLanguages();
    LanguageInfo currentLanguage = languages.FirstOrDefault(l => 
        string.Equals(l.LanguageCode, HttpContext.Current.GetLanguage(), StringComparison.OrdinalIgnoreCase)
    );
 %>

<div id="language-drop-down-list" class="country-flags">
    <% if (currentLanguage != null)
       { %>
        <img title="<%= currentLanguage.DisplayName.SafeHtmlEncode() %>" src="//cdn.everymatrix.com/images/transparent.gif" class="<%= currentLanguage.CountryFlagName.SafeHtmlEncode() %>" />
        <%if (ShowNameForCurrentLanguage) { %>
        <span class="language-name"><%= currentLanguage.DisplayName.SafeHtmlEncode()%></span>
        <%} %>
    <% } %>


</div>


<ul id="language-list" class="country-flags" style="display:none">
    <% foreach (LanguageInfo lang in languages)
        {
            if (lang != currentLanguage)
            {
            %>
    <li>
        <a href="<%= GetUrlWithLanguage(lang.LanguageCode).SafeHtmlEncode() %>" title="<%= lang.DisplayName.SafeHtmlEncode() %>">
            <img border="0" src="//cdn.everymatrix.com/images/transparent.gif"  class="<%= lang.CountryFlagName.SafeHtmlEncode() %>" />
            <span class="language-name"><%= lang.DisplayName.SafeHtmlEncode() %></span>
        </a>
    </li>
    <%      }
        }%>
</ul>


<script language="javascript" type="text/javascript">
    function displayLanguageOptions()
    {
        $('#language-list').detach().appendTo(document.body);
        $('#language-list').css('position', 'absolute');
        $('#language-list').css('left', $('#language-drop-down-list').offset().left.toString(10) + 'px');
        $('#language-list').css('top', ($('#language-drop-down-list').offset().top + $('#language-drop-down-list').outerHeight()).toString(10) + 'px');
        $('#language-list').fadeIn('fast');
        $("#language-drop-down-list").addClass("language-active");        
    }

    function hideLanguageOptions()
    {
        $('#language-list').hide();
        $("#language-drop-down-list").removeClass("language-active");
    }
    
    $(document).ready(function () {
        <%if(!string.IsNullOrEmpty(DisplayModel) && DisplayModel.Equals("mouseenter",StringComparison.OrdinalIgnoreCase)){
        %>
        $('#language-drop-down-list').mouseover(function (e) {
            displayLanguageOptions();
            return false;
        });

        $("#language-list").mouseover(function () {
            return false;
        });

        $(document.body).mouseover(function () {
            hideLanguageOptions();
        });
        <%
        }
        else{
        %>
        $('#language-drop-down-list').click(function (e) {
            displayLanguageOptions();
        });        
        <%
        } %>
           
        $(document.body).mouseup(function () {
            hideLanguageOptions();
        });     
    });
    
</script>