<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<script type="text/C#" runat="server">
	private List<MenuSectionData> NavigationData;

	private struct MenuItemData
	{
		public string Id;
		public string Url;
		public bool Disabled;
		public int Visibility;// default = always; 1 = user only; 2 = anonymous only;
	}

	private struct MenuSectionData
	{
		public string Id;
		public List<MenuItemData> Items;
	}
	
	protected override void OnInit(EventArgs e)
	{
		NavigationData = new List<MenuSectionData>()
		{
			new MenuSectionData
			{
				Id = "Section_Main",
				Items = new List<MenuItemData>
				{
					new MenuItemData { Id = "Home", Url = Url.RouteUrl("Home") },
					new MenuItemData { Id = "Sports", Url = Url.RouteUrl("Sports_Home"), Disabled = !Settings.Vendor_EnableSports },
					new MenuItemData { Id = "Casino", Url = Url.RouteUrl("CasinoLobby"), Disabled = !Settings.Vendor_EnableCasino }
				}
			},
			new MenuSectionData
			{
				Id = "Section_Util",
				Items = new List<MenuItemData>
				{
					new MenuItemData { Id = "Deposit", Url = Url.RouteUrl("Deposit"), Visibility = 1 },
					new MenuItemData { Id = "Transfer", Url = Url.RouteUrl("Transfer"), Visibility = 1 },
					new MenuItemData { Id = "TransHistory", Url = Url.RouteUrl("AccountStatement"), Visibility = 1 },
					new MenuItemData 
					{ 
						Id = "OM_BetHistory", Url = Url.RouteUrl("Sports_Home", new { @pageURL=this.GetMetadata("/Metadata/Settings/.OddsMatrix_BetHistoryUrl") }), 
						Visibility = 1, Disabled = !Settings.Vendor_EnableSports
					},
					new MenuItemData { Id = "WithdrawPend", Url = Url.RouteUrl("PendingWithdrawal"), Visibility = 1 },
					new MenuItemData { Id = "Withdraw", Url = Url.RouteUrl("Withdraw"), Visibility = 1 },
					new MenuItemData { Id = "Logout", Url = Url.RouteUrl("Login", new { @action = "SignOut" }), Visibility = 1 },
					new MenuItemData { Id = "Profile", Url = Url.RouteUrl("Profile"), Visibility = 1 },
					new MenuItemData { Id = "Bonuses", Url = Url.RouteUrl("AvailableBonus"), Visibility = 1 },
					
					new MenuItemData { Id = "Signup", Url = Url.RouteUrl("Register"), Visibility = 2 },
					new MenuItemData { Id = "Login", Url = Url.RouteUrl("Login"), Visibility = 2 },
					
					new MenuItemData { Id = "Settings", Url = Url.RouteUrl("AccountSettings") },
					new MenuItemData 
					{ 
						Id = "OM_BettingSlip", Url = Url.RouteUrl("Sports_Home", new { @pageURL=this.GetMetadata("/Metadata/Settings/.OddsMatrix_BettingSlipUrl") }), 
						Disabled = !Settings.Vendor_EnableSports
					},
				}
			},
			new MenuSectionData
			{
				Id = "Section_Info",
				Items = new List<MenuItemData>
				{
					new MenuItemData { Id = "About", Url = Url.RouteUrl("AboutUs") },
					new MenuItemData { Id = "Help", Url = Url.RouteUrl("Help") },
					new MenuItemData { Id = "Promotions", Url = Url.RouteUrl("Promotions_Home") },
					new MenuItemData { Id = "Winners", Url = Url.RouteUrl("Winners"), Disabled = !Settings.Vendor_EnableCasino },//TODO: implement sports section and remove check
					new MenuItemData { Id = "Popular", Url = Url.RouteUrl("Popular"), Disabled = !Settings.Vendor_EnableCasino },//TODO: implement sports section and remove check
					new MenuItemData { Id = "Terms", Url = Url.RouteUrl("TermsConditions") },
					new MenuItemData { Id = "Responsible", Url = Url.RouteUrl("ResponsibleGaming") },
					new MenuItemData { Id = "Contact", Url = Url.RouteUrl("ContactUs") },
				}
			}
		};
		
 		base.OnInit(e);
	}
</script>

<% 
	foreach (MenuSectionData section in NavigationData)
	{
%>
<h2 class="Section"><span class="SectionText"><%= this.GetMetadata(string.Format(".{0}", section.Id)).SafeHtmlEncode()%></span></h2>
<ol class="MenuList L">
	<% 
		foreach (MenuItemData item in section.Items)
		{
			bool showItem = true;
			switch (item.Visibility)
			{
				case 1:
					showItem = Profile.IsAuthenticated;
					break;
				case 2:
					showItem = !Profile.IsAuthenticated;
					break;
			}

			if (showItem && !item.Disabled)
			{
		%>
		<li class="MenuItem <%= string.Format("{0}Page", item.Id).SafeHtmlEncode()%> X">
			<a class="MenuLink A Container" href="<%= item.Url.SafeHtmlEncode()%>"> <span class="ActionArrow Y">&#9658;</span> <span class="Page I">Page</span> <span class="PageName N"><%= this.GetMetadata(string.Format(".{0}", item.Id)).SafeHtmlEncode()%></span> </a>
		</li>
		<%	
			}
		}
	%>
</ol>
<%
	} 
%>