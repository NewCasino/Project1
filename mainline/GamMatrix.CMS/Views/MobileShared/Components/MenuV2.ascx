<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.MenuV2ViewModel>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components"  %>

 

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

<div id="Header" class="Header2"> 
    <div class="MenuContainer">
        <ul class="MenuList HeaderMenu HeaderButtons">

            <li class="HeaderMenuItem MainMenuItem">
                <a id="btnMainMenu" class="Button HeaderBTN MainMenuBTN">
                    <span class="ButtonIcon icon-MainMenu">&nbsp;</span>
                    <span class="ButtonText"><%= this.GetMetadata(".MainMenu_Text") %></span>
                </a>
            </li>

            <% if (Profile.IsAuthenticated) { %>
            
                <li class="HeaderMenuItem">
                    <a id="btnAccountMenu" class="Button HeaderBTN AccountMenuBTN">
                         <span class="ButtonIcon icon-AccountMenu">&nbsp;</span>
                         <span class="ButtonText"><%= this.GetMetadata(".Account_Text") %></span>
                    </a>
                </li>

            <% } else { %>
                
                <li class="HeaderMenuItem SignInItem">
                    <a id="btnSignIn" class="Button HeaderBTN SignInBTN" href="<%= Url.RouteUrl("Login") %>">
                         <span class="ButtonIcon icon-SignIn">&nbsp;</span>
                         <span class="ButtonText"><%= this.GetMetadata(".SignIn_Text") %></span>
                    </a>
                </li>

            <% } %>

            <% foreach(var sectionItem in Model.SectionItems) {
                   if (IsRestricted(sectionItem.EntryId))
                       continue;
                   %>

                <li class="HeaderMenuItem SectionButton Item-<%= sectionItem.CssClass %>">
                    <a class="Button HeaderBTN BTN-<%= sectionItem.CssClass %>" href="<%= sectionItem.Url %>">
                        <span class="ButtonIcon icon-<%= sectionItem.CssClass %>">&nbsp;</span>
                        <span class="ButtonText"><%= GetText(sectionItem.EntryId) %></span>
                    </a>
                </li>

            <% } %>

            <li class="HeaderMenuItem ClientLogoBox">
                <a id="HeaderLogo" href="/" class="HeaderLogo BTN-Logo" title="{Client Name}">
                    <span class="ButtonIcon Logo-Icon" style="background-image:url('<%= this.GetMetadata("/Metadata/Settings/.Operator_LogoUrl").SafeHtmlEncode() %>');"> </span>
                    <span class="HeaderButtonText">{Client Name}</span>
                </a>
            </li>
        </ul>
    </div>

<div id="mainMenuContainer" class="SideMenu MainMenuBox">
    <ul class="SideMenuList MainMenuEntries ">
    <% foreach(var mainMenuEntry in Model.MainMenuEntries) {
           if (IsRestricted(mainMenuEntry.EntryId))
               continue;
           %>
    
        <li class="MenuItem MainMenuItem Item-<%= mainMenuEntry.CssClass %> X">
            <a class="SideMenuLink MenuLink SMLink-<%= mainMenuEntry.CssClass %>" href="<%= mainMenuEntry.Url %>">
                <span class="ActionArrow icon-arrow"> </span>
				<span class="ButtonIcon icon-<%= mainMenuEntry.CssClass %>">&nbsp;</span>
				<span class="ButtonText"><%= GetText(mainMenuEntry.EntryId) %></span>
            </a>
        </li>

    <% } %>
    </ul>
</div>

<% if(Profile.IsAuthenticated) { %>

    <div id="accountMenuContainer" class="SideMenu AccountMenuBox ">
        <button id="backToAccountBtn" class="SideMenuLink MenuLink SMLink LoadPartial BackButton" 
            data-partiallink="<%= this.Url.RouteUrl("Menu", new { @action = "AccountMenuPartial" }, Request.IsHttps() ? "https" :"http") %>">
            <span class="ActionArrow icon-arrow-left"> </span>
		    <span class="ButtonIcon icon Hidden">&nbsp;</span>
		    <span class="ButtonText">BACK</span>
        </button>

        <div id="partialLoaderContainer" class="LoaderContainer Hidden">
            <div id="partialLoadingContent" class="LoadingContent">
                <div class="spinner spinner--steps icon-spinner2 LoadingIcon" aria-hidden="true"></div>
                <span id="partialLoadDetails" class="LoadDetails"><%= this.GetMetadata(".PartialLoading_Text").SafeJavascriptStringEncode() %></span>
            </div>
        </div>

        <div id="accountMenuContent" class="AccountMenuContent">
            <% Html.RenderPartial("/Components/AccountMenu", this.Model); %>
        </div>
    </div>

<% } %>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="false">
<script>
    var showLeft = document.getElementById('btnAccountMenu');
    var showRight = document.getElementById('btnMainMenu');
    var menuLeft = document.getElementById('accountMenuContainer');
    var menuRight = document.getElementById('mainMenuContainer');
    var body = document.body;

    var backToAccountBtn = $('#backToAccountBtn');
    backToAccountBtn.addClass('Hidden');

    var $partialLoaderContainer = $('#partialLoaderContainer');
    var $partialLoadDetails = $('#partialLoadDetails');

    if (showLeft != null) {
        showLeft.onclick = function () {
            $(menuLeft).toggleClass('SideMenuOpen');
            if ($(menuRight).is('.SideMenuOpen')) {
                $(menuRight).removeClass('SideMenuOpen');
            }
            $(body).toggleClass('ShowLeftMenu');
            if (!$(body).is('.ShowRightMenu')) {
                $('.DisableFramework').toggleClass('Hidden');
                $('html').toggleClass('DisableOverflow');
                $('.Framework').toggleClass('DisableOverflow');
            }
            $(body).removeClass('ShowRightMenu');
        };
    }

    showRight.onclick = function () {
        $(menuRight).toggleClass('SideMenuOpen');
        if ($(menuLeft).is('.SideMenuOpen')) {
            $(menuLeft).removeClass('SideMenuOpen');
        }
        $(body).toggleClass('ShowRightMenu');
        if (!$(body).is('.ShowLeftMenu')) {
            $('.DisableFramework').toggleClass('Hidden');
            $('html').toggleClass('DisableOverflow');
            $('.Framework').toggleClass('DisableOverflow');
        }
        $(body).removeClass('ShowLeftMenu');
    };

    <% if(Profile.IsAuthenticated) { %>

    var StorageWrapper = typeof (CMS) !== 'undefined' ? CMS.utils.StorageWrapper
        : function (storage) {
            storage = storage || {};

            function set(key, value) {
                if (storage.setItem)
                    storage.setItem(key, value);
            }

            function get(key) {
                if (storage.getItem)
                    return storage.getItem(key);
            }

            function rem(key) {
                if (storage.removeItem)
                    storage.removeItem(key);
            }

            return {
                setItem: set,
                getItem: get,
                removeItem: rem
            }
        };

    var storage = new StorageWrapper(window.sessionStorage);
    var accountPanel = new M360_AccountPanel(storage);
    
    var accountBtn = $('#btnAccountMenu');
    accountBtn.on('click', function () {
        if (!accountPanel.ready())
            accountPanel.refresh();
    });

    $(document).on('AccountPanel:update', function () {
        //StorageWrapper = CMS.utils.StorageWrapper;
        storage = new StorageWrapper(window.sessionStorage);
        accountPanel = new M360_AccountPanel(storage);
        backToAccountBtn.addClass('Hidden');
    });

    <% } %>

    $(body).on('click', '.LoadPartial', function () {
        var loadPartialElement = $(this);
        var accountMenuContent = $("#accountMenuContent");

        accountMenuContent.fadeOut("fast")
                .promise()
                .done(function () {
                    $partialLoaderContainer.removeClass('Hidden');
                    $.ajax({
                        url: loadPartialElement.data('partiallink')
                        , type: "GET"
                        , xhrFields: { withCredentials: true }
                    })
                    .done(function (partialViewResult) {
                        accountMenuContent.html(partialViewResult);
                        $partialLoaderContainer.addClass('Hidden');
                        accountMenuContent.fadeIn("fast");
                        if (loadPartialElement.attr('id') != 'backToAccountBtn') {
                            backToAccountBtn.removeClass('Hidden');
                        }
                    }).fail(function (xhr, textStatus, errorThrown) {
                        $partialLoaderContainer.addClass('Hidden');
                        accountMenuContent.html('<p>' + xhr + '; ' + textStatus + '; ' + errorThrown + '</p>');
                    });
                });
    });
</script>
    </ui:MinifiedJavascriptControl>

    <ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl2" runat="server" AppendToPageEnd="false">
<script type="text/javascript" id='swipejs'>

    $(function () {

        $header = $('#Header');

        //Enable swiping...
        var topEl = $('html');
            
        topEl.swipe({
            //Generic swipe handler for all directions
            swipe: function (event, direction, distance, duration, fingerCount, fingerData) {

                if($header.hasClass('Hidden'))
                    return;

                //console.log("You swiped " + direction);
                if (direction === 'left'
                    && !$(menuRight).hasClass('SideMenuOpen')) {
                    if (!$(body).is('.ShowLeftMenu')) { 
                        //console.log('NO account menu');
                        //console.log('open right menu');
                        $(menuRight).addClass('SideMenuOpen');
                        $(body).addClass('ShowRightMenu');
                        $('.DisableFramework').toggleClass('Hidden');
                        $('html').toggleClass('DisableOverflow');
                        $('.Framework').toggleClass('DisableOverflow');
                    }
                    else {                     //  ---> if account is Open
                        // console.log('NO rightmenu');
                        // console.log('close account menu');
                        $(menuRight).removeClass('SideMenuOpen');
                        $(menuLeft).removeClass('SideMenuOpen');
                        $(body).removeClass('ShowLeftMenu').removeClass('ShowRightMenu');
                        $('.DisableFramework').toggleClass('Hidden');
                        $('html').toggleClass('DisableOverflow');
                        $('.Framework').toggleClass('DisableOverflow');
                    }

                }
                       
                else if (direction === 'right'
                    && !$(menuLeft).hasClass('SideMenuOpen')) {
                    if (!$(body).is('.ShowRightMenu')) { // if NO right menu
                        //console.log('NO rightmenu');
                        if (showLeft != null) {
                            //console.log('open account menu');
                            $(menuLeft).addClass('SideMenuOpen');
                            $(body).addClass('ShowLeftMenu');
                            $(menuRight).removeClass('SideMenuOpen');
                            $(body).removeClass('ShowRightMenu');
                            $('.DisableFramework').toggleClass('Hidden');
                            $('html').toggleClass('DisableOverflow');
                            $('.Framework').toggleClass('DisableOverflow');
                        }
                    }
                    else {                     //  ---> if rightmenu is Open
                        // console.log('close rightmenu ');
                        $(menuRight).removeClass('SideMenuOpen');
                        $(menuLeft).removeClass('SideMenuOpen');
                        $(body).removeClass('ShowLeftMenu').removeClass('ShowRightMenu');
                        $('.DisableFramework').toggleClass('Hidden');
                        $('html').toggleClass('DisableOverflow');
                        $('.Framework').toggleClass('DisableOverflow');
                    }
                }
            },
            triggerOnTouchEnd: false,
            allowPageScroll:"vertical",         //Default is 75px, set to 0 for demo so any distance triggers swipe
            threshold: 100,                 //excludedElements: ".noSwipe",
        });


    });
</script>
        </ui:MinifiedJavascriptControl>

</div>
<div class="overlay Hidden DisableFramework" id="DisableFramework">&nbsp;</div>