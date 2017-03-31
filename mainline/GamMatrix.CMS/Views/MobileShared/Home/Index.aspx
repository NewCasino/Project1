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

    <% if (IsMenuV2Enabled()) { %>

        <%: Html.Partial("/Components/MenuV2", new MenuV2ViewModel(this.Url, showSections: false))%>

    <% } else { %>

        <%: Html.Partial("/Components/HeaderView", new HeaderViewModel { IsLocalSite = true, GenericHomeButton = true })%>

    <% } %>

<div class="Framework <% if (IsV2HomePageEnabled()) { %> FrameWorkStyle2 <% } %>" id="Framework">
	<%--<%= Html.Partial("/Promotions/Home/PresentationList", new PresentationListViewModel("/Metadata/Promotions"))%>--%>
	<div class="Box IntroBox <% if (IsV2HomePageEnabled()) { %> IntroBox_V2 <% } %>" id="IntroBox">
        <% if (IsV2HomePageEnabled()) { %> 
           <!-- v2 -->
		    <ul class="Cols-<%= Model.ActiveSections %> Container IntroBoxOptions_V2" id="HomeButtons">
			    <% if (Model.EnableCasino) { %>
			    <li class="Col CasinoCol_V2">
				    <a class="IntroButton HBCasino_V2" href="<%= this.Url.RouteUrl("CasinoLobby").SafeHtmlEncode()%>" data-preloader="Show-Casino">
					    <span class="HBIcon_V2 icon-CasinoLobbySection"> </span>
                        <span class="HBDescription_V2"><%= this.GetMetadata(".Casino_Description").SafeHtmlEncode()%></span>
					    <strong class="HBText_V2"><%= this.GetMetadata(".Casino").SafeHtmlEncode() %></strong>
				    </a>
			    </li>
			    <% } 
                if (Model.EnableLiveCasino) { %>
			    <li class="Col LiveCasinoCol_V2">
				    <a class="IntroButton HBLiveCasino_V2" href="<%= this.Url.RouteUrl("LiveCasinoLobby").SafeHtmlEncode()%>" data-preloader="Show-LiveCasino">
					    <span class="HBIcon_V2 icon-LiveCasinoSection"> </span>
                        <span class="HBDescription_V2"><%= this.GetMetadata(".LiveCasino_Description").SafeHtmlEncode()%></span>
					    <strong class="HBText_V2"><%= this.GetMetadata(".LiveCasino").SafeHtmlEncode() %></strong>
				    </a>
			    </li>
			    <% } 
                if (Model.EnableSports) { %>
			    <li class="Col SportsCol_V2">
				    <a class="IntroButton HBSports_V2" href="<%= Url.RouteUrl("Sports_Home").SafeHtmlEncode()%>" data-preloader="Show-Sports">
                        <span class="HBIcon_V2 icon-SportsLobbySection"> </span>
                        <span class="HBDescription_V2"><%= this.GetMetadata(".Sports_Description").SafeHtmlEncode() %></span>
					    <strong class="HBText_V2"><%= this.GetMetadata(".Sports").SafeHtmlEncode()%></strong>
				    </a>
			    </li>
			    <% } %>
		    </ul>

         <% } else { %>          
            <!-- v1 -->
            <h2 class="IntroBoxTitle">
			    <span class="IntroBoxLogo"></span>
		    </h2> 
            <ul class="Cols-<%= Model.ActiveSections %> Container IntroBoxOptions" id="HomeButtons">
			    <% if (Model.EnableSports)
			    { %>
			    <li class="Col SportsCol">
				    <a class="HomeButton HBSports" href="<%= Url.RouteUrl("Sports_Home").SafeHtmlEncode()%>" data-preloader="Show-Sports">
					    <span class="HBIcon"><%= this.GetMetadata(".Sports_Description").SafeHtmlEncode() %></span>
					    <strong class="HBText"><%= this.GetMetadata(".Sports").SafeHtmlEncode()%></strong>
				    </a>
			    </li>
			    <% } 
			    if (Model.EnableCasino)
			    { %>
			    <li class="Col CasinoCol">
				    <a class="HomeButton HBCasino" href="<%= this.Url.RouteUrl("CasinoLobby").SafeHtmlEncode()%>" data-preloader="Show-Casino">
					    <span class="HBIcon"><%= this.GetMetadata(".Casino_Description").SafeHtmlEncode()%></span>
					    <strong class="HBText"><%= this.GetMetadata(".Casino").SafeHtmlEncode() %></strong>
				    </a>
			    </li>
			    <% }
			    if (Model.EnableLiveCasino)
			    { %>
			    <li class="Col LiveCasinoCol">
				    <a class="HomeButton HBLiveCasino" href="<%= this.Url.RouteUrl("LiveCasinoLobby").SafeHtmlEncode()%>" data-preloader="Show-LiveCasino">
					    <span class="HBIcon"><%= this.GetMetadata(".LiveCasino_Description").SafeHtmlEncode()%></span>
					    <strong class="HBText"><%= this.GetMetadata(".LiveCasino").SafeHtmlEncode() %></strong>
				    </a>
			    </li>
			    <% } %>
		    </ul>                
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
									                <span class="LanguageText"><%= lang.DisplayName %></span>
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
			                <a class="Button RegisterButton HomeRegisterButton" href="<%= this.Url.RouteUrl("Register", new { @action = "Step1"}) %>">
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
