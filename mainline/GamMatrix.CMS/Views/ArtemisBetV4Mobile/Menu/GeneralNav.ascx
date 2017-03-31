<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Menu.MenuBuilder>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Menu" %>

<script runat="server">
private List<MenuEntry> MenuSection;
private MenuList MenuGeneral;

protected override void OnInit(EventArgs e)
{
MenuSection = Model.BuildEntries(new List<MenuEntry>
{
new MenuEntry
{
ID = "Casino",
Url = Url.RouteUrl("CasinoLobby"),
Restricted = !Settings.Vendor_EnableCasino
},
new MenuEntry
{
ID = "Sports",
Url = Url.RouteUrl("Sports_Home"),
Restricted = !Settings.Vendor_EnableSports
},
new MenuEntry
{
ID = "LiveCasino",
Url = Url.RouteUrl("LiveCasinoLobby"),
Restricted = !Settings.Vendor_EnableLiveCasino
},
}
, "/Metadata/MenuSection");

MenuGeneral = Model.BuildEntries(new List<MenuEntry> 
{
new MenuEntry
{
ID = "About",
Url = Url.RouteUrl("AboutUs"),
},
new MenuEntry
{
ID = "Contact",
Url = Url.RouteUrl("ContactUs"),
},
new MenuEntry
{
ID = "Help",
Url = Url.RouteUrl("Help"),
},
new MenuEntry
{
ID = "Popular",
Url = Url.RouteUrl("Popular"),
Restricted = !Settings.Vendor_EnableCasino
},
new MenuEntry
{
ID = "Promotions",
Url = Url.RouteUrl("Promotions_Home"),
},
new MenuEntry
{
ID = "Responsible",
Url = Url.RouteUrl("ResponsibleGaming"),
},
new MenuEntry
{
ID = "Terms",
Url = Url.RouteUrl("TermsConditions"),
},
new MenuEntry
{
ID = "Winners",
Url = Url.RouteUrl("Winners"),
Restricted = !Settings.Vendor_EnableCasino
},
},
"/Metadata/MenuGeneral", 2);

base.OnInit(e);
}
</script>

<h2 class="Section hidden"><span class="SectionText"><%= this.GetMetadata(".Section_Main").SafeHtmlEncode()%></span></h2>
<ol class="MenuList MainMenuList Container L">
<% 
foreach (MenuEntry entry in MenuSection)
{
%>
<li class="MenuItem <%= entry.CssClass.SafeHtmlEncode() %> X">
<a class="MenuLink A Container" href="<%= entry.Url.SafeHtmlEncode() %>">
<span class="ActionArrow Y">&#9658;</span>
<span class="Page I"><%= this.GetMetadata(".Icon_Page").SafeHtmlEncode()%></span>
<span class="PageName N"><%= entry.Name.SafeHtmlEncode()%></span>
</a>
</li>
<% 
}
%>
</ol>
<div class="MainMenuSecondary Container">
<ol class="MenuList SecondaryMenuList SML1 L">
<% 
foreach (MenuEntry entry in MenuGeneral.GetEntriesForColumn(0))
{
%>
<li class="MenuItem <%= entry.CssClass.SafeHtmlEncode() %> X">
<a class="MenuLink A Container" href="<%= entry.Url.SafeHtmlEncode() %>">
<span class="ActionArrow Y">&#9658;</span>
<span class="Page I"><%= this.GetMetadata(".Icon_Page").SafeHtmlEncode()%></span>
<span class="PageName N"><%= entry.Name.SafeHtmlEncode()%></span>
</a>
</li>
<% 
}
%>
</ol>
<ol class="MenuList SecondaryMenuList SML2 L">
<% 
foreach (MenuEntry entry in MenuGeneral.GetEntriesForColumn(1))
{
%>
<li class="MenuItem <%= entry.CssClass.SafeHtmlEncode() %> X">
<a class="MenuLink A Container" href="<%= entry.Url.SafeHtmlEncode() %>">
<span class="ActionArrow Y">&#9658;</span>
<span class="Page I"><%= this.GetMetadata(".Icon_Page").SafeHtmlEncode()%></span>
<span class="PageName N"><%= entry.Name.SafeHtmlEncode()%></span>
</a>
</li>
<% 
}
%>
</ol>
</div>
<script type="text/javascript">
    if ($('body').hasClass('M360')) {
        $('ol.SML1').append('<li class="MenuItem SettingsPage X"><a class="MenuLink A Container" href="https://msports.artemisbet1000.com/control-panel"><span class="ActionArrow Y">►</span><span class="Page I">Page:</span><span class="PageName N"><%= this.GetMetadata(".Settings_Title")%></span></a></li>')
        console.log('sports');
    }
</script>