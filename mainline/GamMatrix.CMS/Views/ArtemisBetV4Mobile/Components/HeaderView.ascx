<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.HeaderViewModel>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<div class="Fixed">
<div class="LiveSupportWrapper"  >
<a class="Button LiveSupportButton" href="https://server.iad.liveperson.net/hc/59999637/?cmd=file&file=visitorWantsToChat&site=59999637&byhref=1" > Live Support </a>
</div>
<div class="Header" id="headerFixed">
<div class="HeaderWrapper MenuHeaderWrapper Container">
<a class="Button MenuButton" id="generalMenuBtn" href="<%= Url.RouteUrl("Menu").SafeHtmlEncode()%>" data-action="/GeneralNav">
<span class="ButtonIcon"><%= this.GetMetadata(".Icon_Menu").SafeHtmlEncode()%></span>
</a>
<% if (this.Model.HasGenericHome())
{ %>
<a class="Button HomeButtonHeader" href="<%= Url.RouteUrl("Home").SafeHtmlEncode()%>">
<span class="ButtonIcon"><%= this.GetMetadata(".Icon_Home").SafeHtmlEncode()%></span>
</a>
<% }
else if (this.Model.IsLocalSite) 
{ %>
<a class="Button HomeButtonHeader" href="<%= Url.RouteUrl("Home").SafeHtmlEncode()%>">
    <span class="ButtonIcon"><%= this.GetMetadata(".Icon_Home").SafeHtmlEncode()%></span>
</a>
<a class="Button SportsButtonHeader" href="<%= Url.RouteUrl("Sports_Home").SafeHtmlEncode()%>">
    <span class="ButtonIcon"><%= this.GetMetadata(".Icon_Sports").SafeHtmlEncode()%></span>
</a>
<% }
else
{ %>
<a class="Button HomeButtonHeader" href="<%= Url.RouteUrl("Home").SafeHtmlEncode()%>">
    <span class="ButtonIcon"><%= this.GetMetadata(".Icon_Home").SafeHtmlEncode()%></span>
</a>
<a class="Button CasinoButtonHeader" href="<%= this.Url.RouteUrl("CasinoLobby").SafeHtmlEncode()%>">
<span class="ButtonIcon"><%= this.GetMetadata(".Icon_Casino").SafeHtmlEncode()%></span>
</a>
<% } %>
<span class="hidden"><%= this.GetMetadata(".Or").SafeHtmlEncode()%></span>

<%--
<a class="OperatorLogo" id="operatorLogo" href="<%= Url.RouteUrl("Home").SafeHtmlEncode()%>">
<img class="BrandingImage" src="<%= this.GetMetadata("/Metadata/Settings/.Operator_LogoUrl").SafeHtmlEncode() %>" width="150" height="33" alt="<%= this.GetMetadata(".Icon_Logo").SafeHtmlEncode()%>" />
</a> --%>
<% if (!Profile.IsAuthenticated) { %>
<a class="Button RegLink LogInLink" href="<%= this.Model.GetLoginUrl().SafeHtmlEncode() %>" id="loginLink">
    <span class="ButtonText"><%= this.GetMetadata(".Login").SafeHtmlEncode()%></span>
</a>
<% } else { %>
<a class="Button DepositLink" href="/Deposit" id="DepositLink">
    <span class="ButtonText"><%= this.GetMetadata(".Deposit").SafeHtmlEncode()%></span>
</a>
<% } %>

</div>
<div class="MainMenu" id="generalNavMenu">
<div class="GeneralWrapper overthrow">
<div class="MenuData"></div>
<div class="MenuClose">
<a class="Close" href="#">
<span class="CloseWrap">
<span class="CloseIcon">&times;</span>
</span>
</a>
</div>
</div>
</div>
</div>

<% 
if (Profile.IsAuthenticated)
{
%>
<div class="MainMenu AccountMenu AccountPanel" id="accountPanel">
<h2 class="MenuTitle Container toggleAccountMenu">
<span class="MenuTitleWrap" >
<a class="ToggleIcon" href="<%= Url.RouteUrl("Menu").SafeHtmlEncode()%>" data-action="/UserNav" id="accountMenuBtn"><span class="ToggleText"><%= this.GetMetadata(".Toggle").SafeHtmlEncode()%></span> </a>
<strong class="MTText"><%= this.GetMetadata(".MyAccount").SafeHtmlEncode()%></strong>
</span>
</h2>
<div class="AccountList overthrow" id="accountNavMenu">
<div class="AccountWrapper">
<% Html.RenderPartial("/Components/AccountPanel", new AccountPanelViewModel()); %>
<div class="MenuData"></div>
</div>
<div class="MenuClose Logout">
<a class="Button RegLink LogOutLink" href="<%= Url.RouteUrl("Login", new { @action = "SignOut" })%>" id="logoutLink">
<span class="ButtonText"><%= this.GetMetadata(".Logout").SafeHtmlEncode() %></span>
</a>
</div>
</div>
</div>
<%
}
else if (!Model.DisableAccount)
{
%>
<div class="Registry AccountPanel" id="registryFixed">
<ul class="RegList Container">
<li class="RegItem">
<a class="Button RegLink SignUpLink" href="<%= Url.RouteUrl("QuickRegister")%>" id="signUpLink">
<span class="ButtonText"><%= this.GetMetadata(".Signup").SafeHtmlEncode()%></span>
</a>
</li>
<li class="RegItem">
<a class="Button RegLink LogInLink" href="<%= this.Model.GetLoginUrl().SafeHtmlEncode() %>" id="loginLink">
<span class="ButtonText"><%= this.GetMetadata(".Login").SafeHtmlEncode()%></span>
</a>
</li>
</ul>
</div>
<%
}
%>
</div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="false">
<script type="text/javascript">
var M360_Header = (function () { //internal classes in closure
var standalone = window.navigator.standalone;
var StorageWrapper, Dispatcher, AppLinks, NavMenu, NavPos,
storage, redirect, menu;
<% 
if (this.Model.IsLocalSite)
{
%>
StorageWrapper = CMS.utils.StorageWrapper;
Dispatcher = CMS.utils.Dispatcher;
AppLinks = CMS.utils.AppLinks;
NavMenu = CMS.mobile360.views.NavMenu;
NavPos = CMS.mobile360.views.NavPos;
<%
}
else
{
%>
StorageWrapper = function(storage) {
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
}

Dispatcher = function(){
var bindings = {};

function bindEvent(name, handler){
unbindEvent(name, handler);

var handlers = bindings[name];
if (!handlers)
handlers = bindings[name] = [];
handlers.push(handler);

return this;
}

function unbindEvent(name, handler){
var handlers = bindings[name];
if (!handlers) return this;

var index = $.inArray(handler, handlers)
if (index != -1)
handlers.splice(index, 1);
if (!handlers.length)
delete bindings[name];

return this;
}

function triggerEvent(name, data){
var handlers = bindings[name];
if (!handlers) return this;

for (var i = 0; i < handlers.length; i++)
handlers[i](data);

return this;
}

return{
bind: bindEvent,
unbind: unbindEvent,
trigger: triggerEvent
}
}

AppLinks = function(){
function add(element){
if (window.standalone){
$(element).click(function(){
window.location = this.href;
return false;
});
}
}

return {
add: add
}
}

NavMenu = function(settings, dispatcher){
var mainMenu = settings.men, 
menuParent = settings.prt,
menuButton = settings.mbt,
additional = settings.abt,
sessionId = settings.sid, 
positioner = settings.pos;
var loading, open;

menuButton.click(toggleClickHandler);
$(additional).click(toggleClickHandler);

function toggleClickHandler(){
if (loading === 2)
toggleMenu();
else 
loadMenu();

return false;
}

function loadMenu(){
if (loading === 1)
return;

$.ajax({
url: menuButton.attr('href') + menuButton.data('action') + '?_sid=' + sessionId,
dataType: "html",
success: onMenuReceived,
error: function (jqXHR, textStatus, errorThrown) { menuError(errorThrown); }
});

loading = 1;
}

function toggleMenu(state){
if (state === undefined)
state = !open;
open = state;

if (state){
mainMenu.slideDown();
menuParent.addClass('OpenMenu');
} else {
mainMenu.slideUp();
menuParent.removeClass('OpenMenu');
}

dispatcher.trigger('toggle', state);
}

function onMenuReceived(data) {
try {
$('.MenuData', mainMenu).append($(data));
} catch (error) {
return menuError(error);
}

$('.Close', mainMenu).click(toggleClickHandler);

loading = 2;
dispatcher.trigger('loaded', data);

toggleMenu(true);
if (positioner) 
setTimeout(positioner.calc, 500);
}

function menuError(error) {
console.error('menu error', error);
self.location = menuButton.attr('href');
}

return {
evt: dispatcher,
toggle: toggleMenu
}
}

NavPos = function (settings){
var container = settings.elm,
offset = settings.ofs || 0;

function calculate(){
var viewHeight = $(window).height() - offset,
elementHeight = 0;

container.children().each(function(){
elementHeight += $(this).height();
});

if (elementHeight > viewHeight)
container.css({height: viewHeight + 'px'});
else
container.css({height: 'auto'});
}

container.css('overflow', 'auto');
$(window).resize(calculate);

return {
calc: calculate
}
}
<%
}
%>
storage = new StorageWrapper(window.sessionStorage);
redirect = new AppLinks();

function Navigation() {
var generalMenu, accountMenu;

generalMenu = new NavMenu({
mbt: $('#generalMenuBtn'),
men: $('#generalNavMenu'),
prt: $('#headerFixed'),
sid: '<%= Profile.SessionID.SafeJavascriptStringEncode() %>',
pos: new NavPos({
elm: $('.GeneralWrapper'),
ofs: $('.HeaderWrapper').height() + $('.AccountPanel').height() + 3
})
}, new Dispatcher());
generalMenu.evt.bind('loaded', onMenuLoaded).bind('toggle', onGMenuToggle);
<% 
if (Profile.IsAuthenticated)
{
%>
var accountToggle = $('.toggleAccountMenu'),
accountPanel = new M360_AccountPanel(storage);

accountToggle.click(function(){
if (!accountPanel.ready())
accountPanel.refresh();
});

accountMenu = new NavMenu({
mbt: $('#accountMenuBtn'),
abt: accountToggle,
men: $('#accountNavMenu'),
prt: $('#accountPanel'),
sid: '<%= Profile.SessionID.SafeJavascriptStringEncode() %>',
pos: new NavPos({
elm: $('.AccountList'),
ofs: $('.HeaderWrapper').height() + $('.toggleAccountMenu').height()
})
}, new Dispatcher());
accountMenu.evt.bind('loaded', onMenuLoaded).bind('toggle', onAMenuToggle);
<%
}
%>
function onMenuLoaded(data){
redirect.add($(".MenuLink", data));
}

function onGMenuToggle(state) {
    if (typeof OM === 'object' && typeof OM.Utils === 'object' && typeof OM.Utils.M360_pubsub === 'object') {
        OM.Utils.M360_pubsub.publish('GeneralMenuToggle', [state]);
    }

    if (state && accountMenu) {
        accountMenu.toggle(false);
    }
}

function onAMenuToggle(state) {
    if (typeof OM === 'object' && typeof OM.Utils === 'object' && typeof OM.Utils.M360_pubsub === 'object') {
        OM.Utils.M360_pubsub.publish('AccountMenuToggle', [state]);
    }

if (state)
generalMenu.toggle(false);
}

redirect.add($('.HeaderLink, .BrandingLogo', '#logoutLink'));
}

function M360_Header() {
new Navigation();
}

return M360_Header;
})();

$(function () {
new M360_Header();
});
</script>
</ui:MinifiedJavascriptControl>