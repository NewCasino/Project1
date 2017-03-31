<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Menu.MenuBuilder>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Menu" %>
<%@ Import Namespace="CM.State" %>

<script runat="server">
	private MenuList MenuUser;

	protected override void OnInit(EventArgs e)
	{
		MenuUser = Model.BuildEntries(new List<MenuEntry>
			{
				new MenuEntry
				{
					ID = "AvailableBonuses",
					Url = Url.RouteUrl("AvailableBonus"),
					CssClass = "BonusesPage"
				},
				new MenuEntry
				{
					ID = "BettingHistory",
					Url = Url.RouteUrl("Sports_Home", new { pageURL = this.GetMetadata("/Metadata/Settings/.OddsMatrix_BetHistoryUrl") }),
					Restricted = !Settings.Vendor_EnableSports
				},
				new MenuEntry
				{
					ID = "BettingSlip",
					Url = Url.RouteUrl("Sports_Home", new { pageURL = this.GetMetadata("/Metadata/Settings/.OddsMatrix_BettingSlipUrl") }),
					Restricted = !Settings.Vendor_EnableSports
				},
				new MenuEntry
				{
					ID = "Deposit",
					Url = Url.RouteUrl("Deposit"),
				},
				new MenuEntry
				{
					ID = "PendingWithdrawal",
					Url = Url.RouteUrl("PendingWithdrawal"),
					CssClass = "PendingWPage"
				},
				new MenuEntry
				{
					ID = "Profile",
					Url = Url.RouteUrl("Profile"),
				},
				new MenuEntry
				{
					ID = "Settings",
					Url = Url.RouteUrl("AccountSettings"),
				},
                new MenuEntry
                {
                    ID = "RealityCheck",
                    Url = "/RealityCheck",
                    Restricted = !(CustomProfile.Current.IpCountryID == 230 || CustomProfile.Current.UserCountryID == 230)
                },
				new MenuEntry
				{
					ID = "TransactionHistory",
					Url = Url.RouteUrl("AccountStatement"),
					CssClass = "HistoryPage"
				},
				new MenuEntry
				{
					ID = "Transfer",
					Url = Url.RouteUrl("Transfer"),
				},
				new MenuEntry
				{
					ID = "Withdraw",
					Url = Url.RouteUrl("Withdraw"),
				},
                new MenuEntry
				{
					ID = "CasinoFpp",
					Url = Url.RouteUrl("CasinoFPP",new{@action="Claim"}),
				},
new MenuEntry
{
ID = "BuddyTransfer",
Url = Url.RouteUrl("BuddyTransfer"),
Restricted = !Settings.EnableBuddyTransfer
},
			},
			"/Metadata/MenuUser", 2);
		
		base.OnInit(e);
	}
</script>

<div class="MainMenuSecondary Container">
	<ol class="MenuList SecondaryMenuList SML1 L">
		<% 
			foreach (MenuEntry entry in MenuUser.GetEntriesForColumn(0))
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
			foreach (MenuEntry entry in MenuUser.GetEntriesForColumn(1))
			{
		%>
		<li class="MenuItem <%= entry.CssClass.SafeHtmlEncode()%> X">
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