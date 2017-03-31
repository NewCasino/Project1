using System.Collections.Generic;
using System.Web.Mvc;
using CM.Content;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
    public class MenuV2ViewModel
    {
        public List<MenuV2EntryViewModel> AccountEntries { get; set; }
        public List<MenuV2EntryViewModel> MainMenuEntries { get; set; }
        public List<MenuV2EntryViewModel> SectionItems { get; set; }

        public MenuV2ViewModel(UrlHelper urlHelper
            , bool showSections = true
            , bool showMainMenuEntries = true
            , bool showAccountEntries = true)
        {
            AccountEntries = new List<MenuV2EntryViewModel>();
            MainMenuEntries = new List<MenuV2EntryViewModel>();
            SectionItems = new List<MenuV2EntryViewModel>();

            #region Section items
            if (showSections)
            {
                if (Settings.Vendor_EnableCasino)
                {
                    SectionItems.Add(new MenuV2EntryViewModel()
                    {
                        EntryId = "Casino",
                        Url = urlHelper.RouteUrl("CasinoLobby", new { @action = "index" }),
                        CssClass = "CasinoLobbySection"
                    });
                }

                if (Settings.Vendor_EnableSports)
                {
                    SectionItems.Add(new MenuV2EntryViewModel()
                    {
                        EntryId = "Sports",
                        Url = urlHelper.RouteUrl("Sports_Home", new { @action = "index" }),
                        CssClass = "SportsLobbySection"
                    });
                }

                if (Settings.Vendor_EnableLiveCasino)
                {
                    SectionItems.Add(new MenuV2EntryViewModel()
                    {
                        EntryId = "LiveCasino",
                        Url = urlHelper.RouteUrl("LiveCasinoLobby", new { @action = "index" }),
                        CssClass = "LiveCasinoSection"
                    });
                }
            }
            #endregion

            #region Main menu
            if (showMainMenuEntries)
            {
                MainMenuEntries.Add(new MenuV2EntryViewModel
                {
                    EntryId = "Promotions",
                    Url = urlHelper.RouteUrl("Promotions_Home", new { @action = "index" }),
                    CssClass = "Promotions"
                });

                if (Settings.Vendor_EnableCasino)
                {
                    MainMenuEntries.Add(new MenuV2EntryViewModel
                    {
                        EntryId = "Winners",
                        Url = urlHelper.RouteUrl("Winners", new { @action = "index" }),
                        CssClass = "Winners"
                    });
                }

                MainMenuEntries.Add(new MenuV2EntryViewModel
                {
                    EntryId = "About",
                    Url = urlHelper.RouteUrl("AboutUs", new { @action = "index" }),
                    CssClass = "About"
                });
                MainMenuEntries.Add(new MenuV2EntryViewModel
                {
                    EntryId = "Contact",
                    Url = urlHelper.RouteUrl("ContactUs", new { @action = "index" }),
                    CssClass = "Contact"
                });
                MainMenuEntries.Add(new MenuV2EntryViewModel
                {
                    EntryId = "Help",
                    Url = urlHelper.RouteUrl("Help", new { @action = "index" }),
                    CssClass = "Help"
                });

                //if (Settings.Vendor_EnableCasino)
                //{
                //    MainMenuEntries.Add(new MenuV2EntryViewModel
                //    {
                //        EntryId = "Popular",
                //        Url = urlHelper.RouteUrl("Popular"),
                //        CssClass = "Popular"
                //    });
                //}

                MainMenuEntries.Add(new MenuV2EntryViewModel
                {
                    EntryId = "Terms",
                    Url = urlHelper.RouteUrl("TermsConditions", new { @action = "index" }),
                    CssClass = "Terms"
                });
                MainMenuEntries.Add(new MenuV2EntryViewModel
                {
                    EntryId = "Responsible",
                    Url = urlHelper.RouteUrl("ResponsibleGaming", new { @action = "index" }),
                    CssClass = "Responsible",
                });
            }
            #endregion

            #region Account Menu
            if (showAccountEntries)
            {
                AccountEntries.Add(new MenuV2EntryViewModel
                {
                    EntryId = "Deposit",
                    Url = urlHelper.RouteUrl("Deposit", new { @action = "index" }),
                    CssClass = "Deposit"
                });

                AccountEntries.Add(new MenuV2EntryViewModel
                {
                    EntryId = "Withdraw",
                    Url = urlHelper.RouteUrl("Withdraw", new { @action = "index" }),
                    CssClass = "Withdraw"
                });

                AccountEntries.Add(new MenuV2EntryViewModel
                {
                    EntryId = "PendingWithdrawal",
                    Url = urlHelper.RouteUrl("PendingWithdrawal", new { @action = "index" }),
                    CssClass = "PendingWithdrawal"
                });

                AccountEntries.Add(new MenuV2EntryViewModel
                {
                    EntryId = "TransactionHistory",
                    Url = urlHelper.RouteUrl("AccountStatement", new { @action = "index" }),
                    CssClass = "TransactionHistory"
                });

                AccountEntries.Add(new MenuV2EntryViewModel
                {
                    EntryId = "Transfer",
                    Url = urlHelper.RouteUrl("Transfer", new { @action = "index" }),
                    CssClass = "Transfer"
                });

                AccountEntries.Add(new MenuV2EntryViewModel
                {
                    EntryId = "AvailableBonuses",
                    Url = urlHelper.RouteUrl("AvailableBonus", new { @action = "index" }),
                    CssClass = "BonusesPage"
                });

                AccountEntries.Add(new MenuV2EntryViewModel
                {
                    EntryId = "CasinoFpp",
                    Url = urlHelper.RouteUrl("CasinoFPP", new { @action = "Claim" }),
                    CssClass = "CasinoFpp"
                });

                if (Settings.Vendor_EnableSports)
                {
                    AccountEntries.Add(new MenuV2EntryViewModel
                    {
                        EntryId = "BettingSlip",
                        Url = urlHelper.RouteUrl("Sports_Home", new { @action = "index", pageURL = Metadata.Get("/Metadata/Settings/.OddsMatrix_BettingSlipUrl") }),
                        CssClass = "BettingSlip"
                    });
                    AccountEntries.Add(new MenuV2EntryViewModel
                    {
                        EntryId = "BettingHistory",
                        Url = urlHelper.RouteUrl("Sports_Home", new { @action = "index", pageURL = Metadata.Get("/Metadata/Settings/.OddsMatrix_BetHistoryUrl") }),
                        CssClass = "BettingHistory"
                    });
                }

                AccountEntries.Add(new MenuV2EntryViewModel
                {
                    EntryId = "Profile",
                    Url = urlHelper.RouteUrl("Menu", new { @action = "ViewProfilePartial" }), //urlHelper.RouteUrl("Profile"),
                    CssClass = "Profile",
                    IsLinkEntry = false,
                });
                AccountEntries.Add(new MenuV2EntryViewModel
                {
                    EntryId = "Settings",
                    Url = urlHelper.RouteUrl("Menu", new { @action = "SettingsV2Partial" }),//urlHelper.RouteUrl("AccountSettings"),
                    CssClass = "Settings",
                    IsLinkEntry = false
                });
                AccountEntries.Add(new MenuV2EntryViewModel()
                {
                    EntryId = "SignOut",
                    Url = urlHelper.RouteUrl("Login", new { @action = "SignOut" }),
                    CssClass = "SignOut"
                });
            }
            #endregion

        }
    }
}
