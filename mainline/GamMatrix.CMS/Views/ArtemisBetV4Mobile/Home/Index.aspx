<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Home.HomeViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Promotions.Home" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<script type="text/C#" runat="server">
    protected bool IsV2HomePageEnabled()
    {
        return Settings.MobileV2.IsV2HomePageEnabled;
    }
    protected bool IsMenuV2Enabled()
    {
        return Settings.MobileV2.IsV2MenuEnabled;
    }

    protected bool IsFooterCopyrightHidden()
    {
        return Settings.MobileV2.IsFooterCopyrightHidden;
    }

    protected bool IsHomeRegisterButtonHidden()
    {
        return Settings.MobileV2.IsHomeRegisterButtonHidden;
    }

    protected bool IsLanguageSelectorOnHomePageHidden()
    {
        return Settings.MobileV2.IsLanguageSelectorOnHomePageHidden;
    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>

<asp:content contentplaceholderid="cphMain" runat="Server">
        <%: Html.Partial("/Components/HeaderView", new HeaderViewModel { IsLocalSite = true, GenericHomeButton = true })%>

<div class="Framework" id="Framework">

<% Html.RenderPartial("/Components/TopContent", this.ViewData.Merge(new {@MetaPath = "/Metadata/TopContent/" })); %>

<% Html.RenderPartial("/Promotions/Home/PresentationList", new PresentationListViewModel("/Metadata/Promotions")); %>

<% if (!Profile.IsAuthenticated) { %>
    <% Html.RenderPartial("RegisterWidget"); %>
<% } %>

<div class="Box IntroBox FourBoxes <% if (IsV2HomePageEnabled()) { %> IntroBox_V2 <% } %>" id="IntroBoxes4">   
 <% if (IsV2HomePageEnabled()) { %> v2  <% } else { %>  
    <ul class="Container IntroBoxOptions Custom4Boxes" id="HomeBoxes">
    <% if (Model.EnableSports) { %>
    <li class="Col SportsCol">
        <a class="IntroButton HBSports" href="<%= Url.RouteUrl("Sports_Home").SafeHtmlEncode()%>" data-preloader="Show-Sports">
            <span class="HBoxIm" style="background-image:url('<%= this.GetMetadata(".Sports_IM").SafeHtmlEncode() %>')"> </span>
            <span class="HboxTitle"><%= this.GetMetadata(".Sports_Description").SafeHtmlEncode() %></span>
            <span class="HBText"><%= this.GetMetadata(".Sports").SafeHtmlEncode()%></span>
            <span class="HBoxLink"><%= this.GetMetadata(".SportsCTA") %></span>
        </a>
    </li>
    <% } if (Model.EnableCasino) { %>
    <li class="Col CasinoCol">
        <a class="IntroButton HBCasino" href="<%= this.Url.RouteUrl("CasinoLobby").SafeHtmlEncode()%>" data-preloader="Show-Casino">
              <span class="HBoxIm" style="background-image:url('<%= this.GetMetadata(".Casino_IM").SafeHtmlEncode() %>')"> </span>
              <span class="HboxTitle"><%= this.GetMetadata(".Casino_Description").SafeHtmlEncode() %></span>
              <span class="HBText"><%= this.GetMetadata(".Casino").SafeHtmlEncode()%></span>
              <span class="HBoxLink"><%= this.GetMetadata(".CasinoCTA") %></span>
        </a>
    </li>
    <% } %>
    <%-- } if (Model.EnableLiveCasino) { --%>
    <li class="Col LiveCasinoCol">
        <a class="IntroButton HBLiveCasino" href="<%= this.Url.RouteUrl("LiveCasinoLobby").SafeHtmlEncode()%>" data-preloader="Show-LiveCasino">
              <span class="HBoxIm" style="background-image:url('<%= this.GetMetadata(".LiveCasino_IM").SafeHtmlEncode() %>')"> </span>
              <span class="HboxTitle"><%= this.GetMetadata(".LiveCasino_Description").SafeHtmlEncode() %></span>
              <span class="HBText"><%= this.GetMetadata(".LiveCasino").SafeHtmlEncode()%></span>
              <span class="HBoxLink"><%= this.GetMetadata(".LiveCasinoCTA") %></span>
        </a>
    </li>
    <%-- } --%>
    <li class="Col PromotionsCol">
        <a class="IntroButton HBPromotions" href="/Promotions" data-preloader="Show-Promotions">
              <span class="HBoxIm" style="background-image:url('<%= this.GetMetadata(".Promotions_IM").SafeHtmlEncode() %>')"> </span>
              <span class="HboxTitle"><%= this.GetMetadata(".Promo_Description") %></span>
              <span class="HBText"><%= this.GetMetadata(".Promo") %></span>
              <span class="HBoxLink"><%= this.GetMetadata(".PromoCTA") %></span>
        </a>
    </li>
    </ul>  
<script src="https://zz.connextra.com/dcs/tagController/tag/7d61b44fefd2/homepage?" async defer></script>              
                <%--------------- 
                    Language selector and open new account
                    ---------------%>
                <% bool isHomeRegisterButtonHidden = IsHomeRegisterButtonHidden();
                   bool isLanguageSelectorOnHomePageHidden = IsLanguageSelectorOnHomePageHidden();
                   bool bothHidden = isHomeRegisterButtonHidden
                       && isLanguageSelectorOnHomePageHidden;
                   LanguageInfo[] supportedLanguages = SiteManager.Current.GetSupporttedLanguages();
                   int LangNr = supportedLanguages.Count();
                if (!bothHidden) { %>
                   <div class="CTABox Container">
                        <% if(!isLanguageSelectorOnHomePageHidden) { %>
                <div id="langChooser" class="LanguageChooser lang_<%= SiteManager.Current.GetCurrentLanguage().LanguageCode %>">
                <a id="langDropdownLink" class="LanguageAction MainLanguageAction" href="#">
                <span class="LanguageText"><%= SiteManager.Current.GetCurrentLanguage().DisplayName %></span>
                </a>
                <div class="Dropdown LanguageDropdown LangNr-<%= LangNr %>">
                <ul class="LanguageList Container">
                <% 
                                        foreach (LanguageInfo lang in supportedLanguages)
                                            { 
                %>
                <li class="LanguageItem lang_<%= lang.LanguageCode %>">
                <a class="LanguageAction" href="/<%= string.Format("{0}{1}", lang.LanguageCode, Url.RouteUrl("Home")).SafeHtmlEncode()%>">
                <span class="LanguageText"><%= lang.CountryFlagName %></span>
                </a>
                </li>
                <%
                                            } 
                %>
                </ul>
                </div> 
                </div>

                        <% } //if(!isLanguageSelectorOnHomePageHidden) %>
            <% if (!Profile.IsAuthenticated && !isHomeRegisterButtonHidden) { %>
                <a class="Button RegisterButton HomeRegisterButton" href="<%= this.Url.RouteUrl("QuickRegister", new { @action = "Index"}) %>">
                <strong class="RegText"><%= this.GetMetadata(".Account").SafeHtmlEncode()%></strong>
                </a>
                        <% }  %>
                    </div>
               <% } // Language selector and open new account%>

        <% } //close v1 or v2  %>
</div>
<% Html.RenderPartial("/Components/AddApplication", new AddApplicationViewModel()); %>

<div class="PreLoadingBox hidden">
<div class="PreloadContent">
<div class="PreloadDiv Sports" id="Show-Sports">
<span class="PreloadText"><%= this.GetMetadata(".Sports").SafeHtmlEncode()%></span>
</div>
<div class="PreloadDiv Casino" id="Show-Casino">
<span class="PreloadText"><%= this.GetMetadata(".Casino").SafeHtmlEncode() %></span>
</div>
            <div class="PreloadDiv LiveCasino" id="Show-LiveCasino">
<span class="PreloadText">Live <%= this.GetMetadata(".Casino").SafeHtmlEncode() %></span>
</div>
<div id="loaderDiv" class="loaderDiv">
<span id="loaderImage" data-url="<%= this.GetMetadata(".ImgUrl_Loading").SafeHtmlEncode() %>"></span>
<span class="PreloadingText"><%= this.GetMetadata(".Loading").SafeHtmlEncode() %></span>
</div>
</div>
</div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl2" runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
    function SectionPreloader(loadAnimation) {
        function getDocHeight() {
            height = $(document).height() - 51;
            return height + 'px';
            }
        $('.PreloadContent').css('height', getDocHeight());
        $('#HomeButtons a').on('click', function (evt) {
            evt.preventDefault();
            ShowLoading($(this));
        });
        function ShowLoading(link) {
            $('.PreLoadingBox')
.removeClass('hidden')
.addClass(link.data('preloader'));
            if (loadAnimation)
                loadAnimation.start();
            setTimeout(function () { $('#loaderDiv').fadeIn('slow'); }, 300);
            setTimeout(function () {
                document.location = link.attr('href');
            }, 1500);
        }
    }
    $(function () {
        $('#langDropdownLink').click(function () {
            $('#langChooser').toggleClass('ActiveDropdown');
        });
        $(window).unload(function () {
            $('.PreLoadingBox').addClass('hidden');
        });
        new SectionPreloader();
        CMS.mobile360.Generic.init();
    });
</script>
</ui:MinifiedJavascriptControl>
   
</div>
<%----------
    Footer copyright
    --------%>
    <% if(!IsFooterCopyrightHidden()) { %>
    <%: Html.Partial("/Components/Footer")%>
    <% } %>
</asp:content>
