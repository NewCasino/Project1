using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using CM.Content;
using CM.State;
using CM.Sites;
using GamMatrix.CMS.Integration.OAuth;
using System.Configuration;

/// <summary>
/// Summary description for Settings
/// </summary>
public static class Settings
{
    public static readonly string CLIENT_IDENTITY_COOKIE = "_cic";
    public static readonly string TC_ACCEPTED_COOKIE = "_tca";

    //private static Regex yesRegex = new Regex(@"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled);
    //private static Regex noRegex = new Regex(@"(NO)|(OFF)|(FALSE)|(\0)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled);
    private static readonly HashSet<string> TrueString = new HashSet<string>(new string[] { "YES", "ON", "OK", "TRUE", "1" });
    private static readonly HashSet<string> FalseString = new HashSet<string>(new string[] { "NO", "OFF", "FALSE", "0" });

    public static bool SafeParseBoolString(string text, bool defValue)
    {
        if (string.IsNullOrWhiteSpace(text))
            return defValue;
        string formattedInput = text.Trim().ToUpperInvariant();

        if (TrueString.Contains(formattedInput))
        {
            return true;
        }
        else if (FalseString.Contains(formattedInput))
        {
            return false;
        }
        else
        {
            return defValue;
        }
    }

    private static string[] SafeParseArray(string text)
    {
        if (string.IsNullOrWhiteSpace(text))
            return new string[0];

        List<string> array = new List<string>();
        using (StringReader sr = new StringReader(text))
        {
            while (true)
            {
                string item = sr.ReadLine();
                if (item == null)
                    break;
                if (!string.IsNullOrWhiteSpace(item))
                    array.Add(item.Trim());
            }
        }
        return array.ToArray();
    }

    public static bool GRE_Enabled
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.GRE_Enabled"), false);
        }
    }

    public static bool IovationDeviceTrack_Enabled
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.IovationDeviceTrack_Enabled"), false);
        }
    }

    public static bool IsDenmarkLicenceCheckEnabled
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.IsDenmarkLicenceEnabled"), false);
        }
    }

    public static bool Ukash_AllowPartialDeposit
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.Ukash_AllowPartialDeposit"), true);
        }
    }

    public static string [] Ukash_AllowWithdrawalCCIssueCountries
    {
        get
        {
            return SafeParseArray(Metadata.Get("Metadata/Settings.Ukash_AllowWithdrawalCCIssueCountries"));
        }
    }
    public static string[] WhiteList_EMUserIPs
    {
        get
        {
            return SafeParseArray(Metadata.Get("Metadata/Settings.WhiteList_EMUserIPs"));
        }
    }

    public static string CasinoEngine_OperatorKey {
        get {
            return Metadata.Get("Metadata/Settings.CasinoEngine_OperatorKey");
        }
    }

    public static string CasinoEngine_ApiPassword
    {
        get
        {
            return Metadata.Get("Metadata/Settings.CasinoEngine_ApiPassword");
        }
    }
    public static string BuzzSports_Url
    {
        get
        {
            return Metadata.Get("Metadata/Settings.BuzzSports_Url");
        }
    }

    public static int Payments_Card_CountLimit {
        get
        {
            int max;
            if (int.TryParse(Metadata.Get("Metadata/Settings.Payments_Card_CountLimit"), out max) && max >= 1)
                return max;
            return 3; 
        }
    }

    public static int Payments_LocalBank_Card_CountLimit
    {
        get
        {
            int max;
            if (int.TryParse(Metadata.Get("Metadata/Settings.Payments_LocalBank_Card_CountLimit"), out max) && max >= 1)
                return max;
            return 3;
        }
    }


	/// <summary>
	/// The number of globally popular games to display
	/// </summary>
	public static int PopularLimit_Global
	{
		get
		{
			int max;
			if (int.TryParse(Metadata.Get("Metadata/Settings.PopularLimit_Global"), out max) && max >= 3)
				return max;

			return 3;
		}
	}

	/// <summary>
	/// The number of popular games per category to display
	/// </summary>
	public static int PopularLimit_PerCategory
	{
		get
		{
			int max;
			if (int.TryParse(Metadata.Get("Metadata/Settings.PopularLimit_PerCategory"), out max) && max >= 3)
				return max;

			return 3;
		}
	}

    public static string Password_ValidationRegex
    {
        get
        {
            return Metadata.Get("Metadata/Settings.Password_ValidationRegex").DefaultIfNullOrEmpty("/./g");
        }
    }

    public static bool Transfer_RemoveConfirmationForPopup
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.Transfer_RemoveConfirmationForPopup"), false);
        }
    }

    /// <summary>
    /// the terms conditions url
    /// </summary>
    public static string TermsConditions_Url
    {
        get
        {
            return Metadata.Get("Metadata/Settings.Terms_Conditions_Url");
        }
    }

    /// <summary>
    /// noreply@XXX.com
    /// </summary>
    public static string Email_NoReplyAddress
    {
        get
        {
            return Metadata.Get("Metadata/Settings.Email_NoReplyAddress");
        }
    }


    /// <summary>
    /// the receiver email address for the contact us page
    /// </summary>
    public static string Email_ContactUs
    {
        get
        {
            return Metadata.Get("Metadata/Settings.Email_ContactUs").DefaultIfNullOrEmpty("").Trim();
        }
    }

    /// <summary>
    /// payment@oddsmatrix.com
    /// </summary>
    public static string Email_PaymentAddress
    {
        get
        {
            return Metadata.Get("Metadata/Settings.Email_PaymentAddress");
        }
    }

    /// <summary>
    /// support@XXXX.com
    /// </summary>
    public static string Email_SupportAddress
    {
        get
        {
            return Metadata.Get("Metadata/Settings.Email_SupportAddress");
        }
    }

    /// <summary>
    /// the SMTP server 
    /// </summary>
    public static string Email_SMTP
    {
        get
        {
            return Metadata.Get("Metadata/Settings.Email_SMTP");
        }
    }

    /// <summary>
    /// the SMTP server port
    /// </summary>
    public static int Email_Port
    {
        get
        {
            int port;
            if( int.TryParse( Metadata.Get("Metadata/Settings.Email_Port"), out port) )
                return port;

            return 25;
        }
    }


    /// <summary>
    /// the category id for bingo avatar
    /// </summary>
    public static int Bingo_AvatarCategory
    {
        get
        {
            int max;
            if (int.TryParse(Metadata.Get("Metadata/Settings.Bingo_AvatarCategory"), out max) && max >= 0)
                return max;

            return 3;
        }
    }

    public static string Bingo_GameLoadBaseUrl
    {
        get 
        {
            return Metadata.Get("Metadata/Settings.Bingo_GameLoadBaseUrl").DefaultIfNullOrEmpty("http://bingoclient.nextgamingnetwork.com/13/bingowindow.aspx?rid={0}&s={1}&l={2}&acu={3}");
        }
    }


    public static string EntroPay_ReferrerID
    {
        get
        {
            return Metadata.Get("Metadata/Settings.EntroPay_ReferrerID");
        }
    }

    public static string EntroPay_RegistrationUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.EntroPay_RegistrationUrl");
        }
    }

    public static string[] EntroPay_SensitiveErrorCodes
    {
        get
        {
            return SafeParseArray( Metadata.Get("Metadata/Settings.EntroPay_SensitiveErrorCodes") );
        }
    }

    public static string DeclindedDeposit_SuggestionUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.DeclindedDeposit_SuggestionUrl");
        }
    }

    public static string[] DeclindedDeposit_SensitiveErrorCodes
    {
        get
        {
            return SafeParseArray(Metadata.Get("Metadata/Settings.DeclindedDeposit_SensitiveErrorCodes"));
        }
    }



    public static bool CSS_EnableCompression
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.CSS_EnableCompression"), true);
        }
    }

    public static bool PendingWithdrawal_EnableApprovement
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.PendingWithdrawal_EnableApprovement"), true);
        }
    }

    public static bool Withdrawal_EnablePending
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.Withdrawal_EnablePending"), true);
        }
    }
    public static bool Withdrawal_DisplayBonusAmount
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.Withdrawal_DisplayBonusAmount"), true);
        }
    }


    public static bool EnableBuddyTransfer
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.EnableBuddyTransfer"), true);
        }
    }

	public static bool Vendor_EnableCasino
	{
		get
		{
			return SafeParseBoolString(Metadata.Get("Metadata/Settings.Vendor_EnableCasino"), true);
		}
	}

	public static bool Vendor_EnableLiveCasino
	{
		get
		{
			return SafeParseBoolString(Metadata.Get("Metadata/Settings.Vendor_EnableLiveCasino"), true);
		}
	}

	public static bool Vendor_EnableSports
	{
		get
		{
			return SafeParseBoolString(Metadata.Get("Metadata/Settings.Vendor_EnableSports"), true);
		}
	}

    public static string OddsMatrix_HomePage
    {
        get
        {
            return Metadata.Get("Metadata/Settings.OddsMatrix_HomePage");
        }
    }

    public static bool Casino_3rdPartyVerifySession
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.Casino_3rdPartyVerifySession"), true);
        }
    }

    public static bool Casino_EnableQuickDeposit
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.Casino_EnableQuickDeposit"), false);
        }
    }

    public static string Casino_NetEntGameSkinName
    {
        get
        {
            return Metadata.Get("Metadata/Settings.Casino_NetEntGameSkinName");
        }
    }

    public static string Casino_NetEntGameRulesBaseUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.Casino_NetEntGameRulesBaseUrl");
        }
    }

    public static string Casino_NetEntGameLoadBaseUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.Casino_NetEntGameLoadBaseUrl").DefaultIfNullOrEmpty("https://oddsmatrix-static.casinomodule.com/");
        }
    }

    public static string Casino_NetEntGamePlayBaseUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.Casino_NetEntGamePlayBaseUrl").DefaultIfNullOrEmpty("https://oddsmatrix-game.casinomodule.com/");
        }
    }

    public static string Casino_MicrogamingFunGameUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.Casino_MicrogamingFunGameUrl");
        }
    }

    public static string Casino_MicrogamingRealGameUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.Casino_MicrogamingRealGameUrl");
        }
    }

    public static string Casino_CTXMGameLoadBaseUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.Casino_CTXMGameLoadBaseUrl");
        }
    }

    public static bool Casino_EnableMultipleGame
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.Casino_EnableMultipleGame"), false);
        }
    }

    public static bool Casino_EnableContentProvider
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.Casino_EnableContentProvider"), false);
        }
    }


    public static string LiveCasino_MicrogamingLiveDealerLobbyUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.LiveCasino_MicrogamingLiveDealerLobbyUrl");
        }
    }

    public static string LiveCasino_PALiveAutoRouletteUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.LiveCasino_PALiveAutoRouletteUrl");
        }
    }

    public static string LiveCasino_PALiveDealerRouletteUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.LiveCasino_PALiveDealerRouletteUrl");
        }
    }

    public static string LiveCasino_PAClassicGamesSlotsUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.LiveCasino_PAClassicGamesSlotsUrl");
        }
    }

    public static string LiveCasino_PAClassicGamesSekaUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.LiveCasino_PAClassicGamesSekaUrl");
        }
    }

    public static string LiveCasino_PAClassicGamesBuraUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.LiveCasino_PAClassicGamesBuraUrl");
        }
    }

    public static string LiveCasino_PAClassicGamesDurakaUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.LiveCasino_PAClassicGamesDurakaUrl");
        }
    }


    public static string MergePoker_CurrentTournamentsUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.MergePoker_CurrentTournamentsUrl");
        }
    }

    public static string MergePoker_UpcomingFreerollsUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.MergePoker_UpcomingFreerollsUrl");
        }
    }

    public static string MergePoker_UpcomingGuaranteedsUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.MergePoker_UpcomingGuaranteedsUrl");
        }
    }

    public static string MergePoker_NetworkUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.MergePoker_NetworkUrl");
        }
    }

    public static string EverleafPoker_FlashClientUrl
    {
        get
        {
            return Metadata.Get("Metadata/Settings.EverleafPoker_FlashClientUrl");
        }
    }

    public static string EverleafPoker_TopWinnersFeeds
    {
        get
        {
            return Metadata.Get("Metadata/Settings.EverleafPoker_TopWinnersFeeds");
        }
    }

    public static string EverleafPoker_TopWinners_ExcludedUsers
    {
        get
        {
            return Metadata.Get("Metadata/Settings.EverleafPoker_TopWinners_ExcludedUsers");
        }
    }


    public static bool IsBonusCodeInputEnabled(GamMatrixAPI.VendorID vendorID)
    {
        return SafeParseBoolString( 
            Metadata.Get( string.Format("/Metadata/GammingAccount/{0}.EnableBonusCodeInput", vendorID) )
            , false
            );
    }

    public static bool IsBonusSelectorEnabled(GamMatrixAPI.VendorID vendorID)
    {
        return SafeParseBoolString(
            Metadata.Get( string.Format("/Metadata/GammingAccount/{0}.EnableBonusSelector", vendorID) )
            , false
            );
    }

    public static bool IsOMSeamlessWalletEnabled
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.IsOMSeamlessWalletEnabled"), false);
        }
    }

    public static bool IsBetConstructWalletEnabled
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.IsBetConstructWalletEnabled"), false);
        }
    }

    public static bool Site_IsUnWhitelabel
    {
        get {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.Site_IsUnWhitelabel"), false);
        }
    }

    public static bool Site_IsDeviceCheckerEnabled
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.Site_IsDeviceCheckerEnabled"), false);
        }
    }

	public static bool Site_IsDeviceRedirectForced
	{
		get
		{
			return SafeParseBoolString(Metadata.Get("Metadata/Settings.Site_IsDeviceRedirectForced"), false);
		}
	}

    public static bool EnableLoginViaPersonalID
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.EnableLoginViaPersonalID"), false);
        }
    }

    public static string Site_MobileSiteUrl 
    {
        get 
        {
            string settingUrl = Metadata.Get("Metadata/Settings.Site_MobileSiteUrl");

            if (string.Equals(SiteManager.Current.DistinctName, "Shared", StringComparison.InvariantCultureIgnoreCase)
                || string.Equals(SiteManager.Current.TemplateDomainDistinctName, "Shared", StringComparison.InvariantCultureIgnoreCase))
            {
                string url;
                Dictionary<string, string> mapping = SiteHostMapping.Get(SiteManager.Current.DistinctName);
                if (mapping.TryGetValue(HttpContext.Current.Request.Url.Host, out url))
                {
                    if (!url.StartsWith("http://", StringComparison.InvariantCultureIgnoreCase)
                        && !url.StartsWith("https://", StringComparison.InvariantCultureIgnoreCase))
                    {
                        if (SiteManager.Current.HttpsPort > 0)
                        {
                            if (SiteManager.Current.HttpsPort == 443)
                                url = string.Format("https://{0}/", url);
                            else
                                url = string.Format("https://{0}:{1}/", url, SiteManager.Current.HttpsPort);
                        }
                        else
                        {
                            if (SiteManager.Current.HttpPort == 80)
                                url = string.Format("http://{0}/", url);
                            else
                                url = string.Format("http://{0}:{1}/", url, SiteManager.Current.HttpPort);
                        }
                    }
                    return url;
                }
            }

            return settingUrl;
        }
    }

    public static string Site_PCSiteUrl
    {
        get
        {
            string settingUrl = Metadata.Get("Metadata/Settings.Site_PCSiteUrl");

            if (string.Equals(SiteManager.Current.DistinctName, "MobileShared", StringComparison.InvariantCultureIgnoreCase)
                || string.Equals(SiteManager.Current.TemplateDomainDistinctName, "MobileShared", StringComparison.InvariantCultureIgnoreCase))
            {
                string url;
                Dictionary<string, string> mapping = SiteHostMapping.Get(SiteManager.Current.DistinctName);
                if (mapping.TryGetValue(HttpContext.Current.Request.Url.Host, out url))
                {
                    if (!url.StartsWith("http://", StringComparison.InvariantCultureIgnoreCase)
                        && !url.StartsWith("https://", StringComparison.InvariantCultureIgnoreCase))
                    {
                        if (SiteManager.Current.HttpsPort > 0)
                        {
                            if (SiteManager.Current.HttpsPort == 443)
                                url = string.Format("https://{0}/", url);
                            else
                                url = string.Format("https://{0}:{1}/", url, SiteManager.Current.HttpsPort);
                        }
                        else
                        {
                            if (SiteManager.Current.HttpPort == 80)
                                url = string.Format("http://{0}/", url);
                            else
                                url = string.Format("http://{0}:{1}/", url, SiteManager.Current.HttpPort);
                        }
                    }
                    return url;
                }
            }

            return settingUrl;
        }
    }

    public static int NumberOfDaysForLoginWithoutEmailVerification
    {
        get {
            return CM.State.CustomProfile.Current.NumberOfDaysForLoginWithoutEmailVerification;
            //int days = 7;
            //if (int.TryParse(Metadata.Get("Metadata/Settings.NumberOfDaysForLoginWithoutEmailVerification"), out days))
            //{
            //    return days;
            //}
            //return 7;
        }
    }

    public static bool Password_CheckPasswordHistory
    {
        get {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.Password_CheckPasswordHistory"), false);
        }
    }

    #region Affiliate
    public static class Affiliate {
        public static int Btag_CookieExpiresMinutes
        {
            get
            {
                int _temp;
                if (int.TryParse(Metadata.Get("Metadata/Settings/Affiliate.Btag_CookieExpiresMinutes"), out _temp))
                {
                    return _temp;
                }
                return 43200;
            }
        }

        public static string Btag_FormatExpression
        {
            get
            {
                return Metadata.Get("Metadata/Settings/Affiliate.Btag_FormatExpression");
            }
        }
    }
    #endregion Affiliate

    #region DKLicense
    public static class DKLicense {
        public static bool IsIDQCheck
        {
            get
            {
                if (!IsDKLicense)
                    return false;
                if ( !SafeParseBoolString(Metadata.Get("Metadata/Settings/DKLicense.IsIDQCheck"), false))
                    return false;
                if (CustomProfile.Current.IpCountryID == 64 || CustomProfile.Current.UserCountryID == 64)
                    return true;
                return false;
            }
        }
        public static bool IsDKLoginPopup
        {
            get
            {
                if (!SafeParseBoolString(Metadata.Get("Metadata/Settings/DKLicense.IsDKLoginPopup"), false))
                    return false;
                if (CustomProfile.Current.IpCountryID == 64 || CustomProfile.Current.UserCountryID == 64)
                    return true;

                return false;
            }
        }

        public static string DKTempAccountRole
        {
            get
            {
                return Metadata.Get("Metadata/Settings/DKLicense.TemporaryAccountRoleName").DefaultIfNullOrEmpty("");
            }

        }
        public static string DKTempAccountExpireMsg
        {
            get
            {
                return Metadata.Get("Metadata/ServerResponse.Login_Blocked_AccountExpire").DefaultIfNullOrEmpty("Your account is blocked!");
            }
        }
        public static bool IsDKTempAccountEnbaled
        {
            get
            {
                return SafeParseBoolString(CM.Content.Metadata.Get("Metadata/Settings/DKLicense.EnabledTemporaryAccount"), false);
            }
        }
        public static int DKTempAccountExpireDayNum
        {

            get
            { 
                int daynum = 30;
                int.TryParse(CM.Content.Metadata.Get("Metadata/Settings/DKLicense.TemporaryAccountMaximumDays"), out daynum);
                return daynum;
            }
        }

    }
    #endregion

    #region Registration
    public static class Registration
    {
        /// <summary>
        /// The max attempts of registration from same ip per day
        /// </summary>
        public static int SameIPLimitPerDay
        {
            get
            {
                int max;
                if (int.TryParse(Metadata.Get("Metadata/Settings/Registration.SameIPLimitPerDay"), out max) && max >= 0)
                    return max;

                return 5;
            }
        }

        /// <summary>
        /// when  true, will set email value to username
        /// </summary>
        public static bool IsUseEmailForUsername
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsUseEmailForUsername").DefaultIfNullOrEmpty("no"), false);
            }
        }
        /// <summary>
        /// when  true, will Check DK IDQ status
        /// </summary>
        public static bool IsDKIDQCheck
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsDKIDQCheck").DefaultIfNullOrEmpty("no"), false);
            }
        }

        /// <summary>
        /// 
        /// </summary>
        public static bool IsDkTitleAutoSetByCPRNumber
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsDkTitleAutoSetByCPRNumber").DefaultIfNullOrEmpty("no"), false);
            }
        }

        /// <summary>
        /// when  true,  update DK External Register information to db
        /// </summary>
        public static bool IsDKExternalRegister
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsDKExternalRegister").DefaultIfNullOrEmpty("no"), false);
            }
        }
        /// <summary>
        /// when  true, will check cpr and age when send register to db
        /// </summary>
        public static bool IsVerifyCprAndAge
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsVerifyCprAndAge").DefaultIfNullOrEmpty("no"), false);
            }
        }
        /// <summary>
        /// when  true, will check captcha
        /// </summary>
        public static bool IsCaptchaRequired
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsCaptchaRequired").DefaultIfNullOrEmpty("no"), false);
            }
        }
        /// <summary>
        /// The max attempts of registration from same ip per day
        /// </summary>
        public static string[] SameIPLimitWhitelist
        {
            get
            {
                return Metadata.Get("Metadata/Settings/Registration.SameIPLimitWhitelist")
                    .Split(new char[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
            }
        }

        /// <summary>
        /// The legal age of registration
        /// </summary>
        public static int LegalAge
        {
            get
            {
                int max;
                if (int.TryParse(Metadata.Get("Metadata/Settings/Registration.LegalAge"), out max) && max >= 1)
                    return max;

                return 18;
            }
        }

        /// <summary>
        /// The max length of the username
        /// </summary>
        public static int UsernameMaxLength
        {
            get
            {
                int max;
                if (int.TryParse(Metadata.Get("Metadata/Settings/Registration.UsernameMaxLength"), out max) && max > 10)
                    return max;

                return 15;
            }
        }

        public static bool EnableLgaDunplicateAccountVerification
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.EnableLgaDunplicateAccountVerification"), true);
            }
        }

        public static bool AvoidSameUsernamePassword
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.AvoidSameUsernamePassword"), true);
            }
        }

        public static bool DisableAutoLogin
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.DisableAutoLogin"), false);
            }
        }

        public static bool AutoLoginAfterActivation
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.AutoLoginAfterActivation"), false);
            }
        }

        /// <summary>
        /// the disallowed email domain
        /// </summary>
        public static string[] DisallowedEmailDomain
        {
            get
            {
                return Metadata.Get("Metadata/Settings/Registration.DisallowedEmailDomain")
                    .Split(new char[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
            }
        }

        public static bool DisallowDuplicateMobile
        {
            get {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.DisallowDuplicateMobile"), false);
            }
        }

        public static bool UsenameAsAlias
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.UsenameAsAlias"), false);
            }
        }

        public static bool IsTitleVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsTitleVisible"), true);
            }
        }

        public static bool IsTitleRequired
        {
            get
            {
                return Settings.Registration.IsTitleVisible &&
                    SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsTitleRequired"), true);
            }
        }

        public static bool IsAliasVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsAliasVisible"), true);
            }
        }

        public static bool IsAliasRequired
        {
            get
            {
                return Settings.Registration.IsAliasVisible &&
                    SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsAliasRequired"), true);
            }
        }

        public static bool IsAvatarVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsAvatarVisible"), true);
            }
        }

        public static bool IsFirstnameVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsFirstnameVisible"), true);
            }
        }

        public static bool IsFirstnameRequired
        {
            get
            {
                return Settings.Registration.IsFirstnameVisible &&
                    SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsFirstnameRequired"), true);
            }
        }

        public static bool IsSurnameVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsSurnameVisible"), true);
            }
        }

        public static bool IsSurnameRequired
        {
            get
            {
                return Settings.Registration.IsSurnameVisible &&
                    SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsSurnameRequired"), true);
            }
        }

        public static bool IsBirthDateVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsBirthDateVisible"), true);
            }
        }

        public static bool IsBirthDateRequired
        {
            get
            {
                return Settings.Registration.IsBirthDateVisible &&
                    SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsBirthDateRequired"), true);
            }
        }

        public static bool IsRepeatEmailVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsRepeatEmailVisible"), true);
            }
        }

        public static bool IsAddress1Visible
        {
            get
            {
                return !Settings.Registration.IsStreetRequired && 
                    SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsAddress1Visible"), true);
            }
        }

        public static bool IsAddress1Required
        {
            get
            {
                return Settings.Registration.IsAddress1Visible &&
                    SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsAddress1Required"), true);
            }
        }

        public static bool IsAddress2Visible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsAddress2Visible"), true);
            }
        }

        public static bool IsCityVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsCityVisible"), true);
            }
        }

        public static bool IsCityRequired
        {
            get
            {
                return Settings.Registration.IsCityVisible &&
                    SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsCityRequired"), true);
            }
        }

        public static bool IsPostalCodeVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsPostalCodeVisible"), true);
            }
        }

        public static bool IsPostalCodeRequired
        {
            get
            {
                return Settings.Registration.IsPostalCodeVisible &&
                    SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsPostalCodeRequired"), true);
            }
        }

        public static bool IsMobileVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsMobileVisible"), true);
            }
        }

        public static bool IsMobileRequired
        {
            get
            {
                return Settings.Registration.IsMobileVisible &&
                    SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsMobileRequired"), true);
            }
        }

        public static bool IsRepeatMobileVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsRepeatMobileVisible"), false);
            }
        }

        public static bool IsPhoneVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsPhoneVisible"), true);
            }
        }

        public static bool IsSecurityQuestionVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsSecurityQuestionVisible"), true);
            }
        }

        public static bool IsSecurityQuestionRequired
        {
            get
            {
                return Settings.Registration.IsSecurityQuestionVisible &&
                    SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsSecurityQuestionRequired"), true);
            }
        }

        public static bool IsSecurityAnswerVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsSecurityAnswerVisible"), IsSecurityQuestionVisible);
            }
        }

        public static bool IsSecurityAnswerRequired
        {
            get
            {
                return Settings.Registration.IsSecurityAnswerVisible &&
                    SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsSecurityAnswerRequired"), IsSecurityQuestionRequired);
            }
        }

        public static bool IsRegionVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsRegionVisible"), true);
            }
        }

        public static bool IsPersonalIDVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsPersonalIDVisible"), false);
            }
        }

        public static bool IsPersonalIDRequired
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsPersonalIDRequired"), false);
            }
        }

        public static bool IsRegionIDRequired
        {
            get
            {
                return Settings.Registration.IsSecurityQuestionVisible &&
                    SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsRegionIDRequired"), false);
            }
        }

        public static bool IsRegionIDVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsRegionIDVisible"), false);
            }
        }

        public static bool RequireActivation
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.RequireActivation"), true);
            }
        }

        public static bool SendWelcomeEmail
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.SendWelcomeEmail"), false);
            }
        }

        /// <summary>
        /// the max length of password
        /// </summary>
        public static int PasswordMaxLength
        {
            get
            {
                int max;
                if (int.TryParse(Metadata.Get("Metadata/Settings/Registration.PasswordMaxLength"), out max) && max > 10)
                    return max;

                return 20;
            }
        }

        /// <summary>
        /// the min length of password
        /// </summary>
        public static int PasswordMinLength
        {
            get
            {
                int min;
                if (int.TryParse(Metadata.Get("Metadata/Settings/Registration.PasswordMinLength"), out min) && min > 7)
                    return min;

                return 7;
            }
        }

        public static bool IsPassportRequired
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsPassportRequired"), false);
            }
        }

        public static bool IsPassportVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsPassportVisible"), false);
            }
        }

        public static bool IsStreetRequired
        {
            get
            {
                return Settings.Registration.IsStreetVisible &&
                    SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsStreetRequired"), false);
            }
        }

        public static bool IsStreetVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Registration.IsStreetVisible"), false);
            }
        }

    }
    #endregion Registration

    #region Qucik Regiostration
    public static class QuickRegistration
    {
        //public static bool IsCurrencyVisible {
        //    get
        //    {
        //        return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsCurrencyVisible"), true);
            
        //    }
        //}
        public static bool IsUserNameVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsUserNameVisible"), true);
            }
        }

        public static bool IsTermsConditionsVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsTermsConditionsVisible"), true);
            }
        }

        public static bool IsMobileVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsMobileVisible"), false);
            }
        }

        public static bool IsFirstnameVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsFirstnameVisible"), false);
            }
        }

        public static bool IsSurnameVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsSurnameVisible"), false);
            }
        }

        public static bool IsBirthDateVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsBirthDateVisible"), false);
            }
        }

        public static bool IsRepeatEmailVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsRepeatEmailVisible"), true);
            }
        }

        public static bool IsAddress1Visible
        {
            get
            {
                return !IsStreetVisible && SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsAddress1Visible"), false);
            }
        }

        public static bool IsStreetVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsStreetVisible"), false);
            }
        }

        public static bool IsCityVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsCityVisible"), false);
            }
        }

        public static bool IsPostalCodeVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsPostalCodeVisible"), false);
            }
        }

        public static bool IsCountryVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsCountryVisible"), false);
            }
        }

        public static bool IsRegionVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsRegionVisible"), false);
            }
        }

        public static bool IsPersonalIDVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsPersonalIDVisible"), false);
            }
        }

        public static bool IsTitleVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsTitleVisible"), false);
            }
        }

        public static bool IsSecurityQuestionVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsSecurityQuestionVisible"), false);
            }
        }

        public static bool IsSecurityAnswerVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsSecurityAnswerVisible"), false);
            }
        }

        public static bool IsLanguageVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsLanguageVisible"), false);
            }
        }

        public static bool IsAllowNewsEmailVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsAllowNewsEmailVisible"), true);
            }
        }

        public static bool IsAllowSmsOfferVisible
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsAllowSmsOfferVisible"), true);
            }
        }

        public static bool IsCaptchaRequired
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/QuickRegistration.IsCaptchaRequired").DefaultIfNullOrEmpty("no"), false);
            }
        }
    }
    #endregion Qucik Regiostration

    #region 
    public static class LimitSetPopup
    {
        public static bool Enabled
        {
            get
            {
                if (!SafeParseBoolString(Metadata.Get("Metadata/Settings/LimitSetPopup.Enabled"), false))
                    return false;

                try
                {
                    string[] countryIDs = SafeParseArray(Metadata.Get("Metadata/Settings/LimitSetPopup.CountryIDs"));

                    IPLocation ipLocation = IPLocation.GetByIP(HttpContext.Current.Request.GetRealUserAddress());
                    return countryIDs.Contains(ipLocation.CountryID.ToString(CultureInfo.InvariantCulture));
                }
                catch
                {
                    return false;
                }


                return SafeParseBoolString(Metadata.Get("Metadata/Settings/LimitSetPopup.Enabled"), true);
            }
        }
    }
    #endregion

    public static bool LockCountryPaymentsFIlterForLoginUsers
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.LockCountryPaymentsFIlterForLoginUsers"), false);
        }
    }

    public static bool LockCurrencyPaymentsFIlterForLoginUsers
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.LockCurrencyPaymentsFIlterForLoginUsers"), false);
        }
    }


    public static decimal MinJackpotValue 
    {
        get
        {
            decimal minV = 0;
            string strMinV = Metadata.Get("Metadata/Settings.MinJackpotValue");
            if (!string.IsNullOrEmpty(strMinV))
            {
                decimal.TryParse(Metadata.Get("Metadata/Settings.MinJackpotValue"), out minV);
            }
            return minV;
        }
    }

    public static bool Switch_NegactiveLimit
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.Switch_NegactiveLimit"), false);
        }
    }

    public static string DKLicenseKey {
        get
        {
            try
            {
                string html = Metadata.Get("Metadata/Settings/DKLicense.DKLicenseKey");
                if (html == null || string.IsNullOrEmpty(html))
                {
                    html = ConfigurationManager.AppSettings["GmCore.OperatorSecret"].ToString();
                }
                return html;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return ConfigurationManager.AppSettings["GmCore.OperatorSecret"].ToString();
            }
        }
    }
    public static bool IsDKLicense
    {
        get
        {

            if (SafeParseBoolString(Metadata.Get("Metadata/Settings/DKLicense.IsForceDKLicense"), false))
                return true;

            if (!SafeParseBoolString(Metadata.Get("Metadata/Settings/DKLicense.IsDKLicense"), false))
                return false;

            IPLocation ipLocation = IPLocation.GetByIP(HttpContext.Current.Request.GetRealUserAddress());
            if (ipLocation.CountryID == 64 || ipLocation.CountryID == 0 || SafeParseBoolString(Metadata.Get("Metadata/Settings/DKLicense.IsForceDKLicense"), false)) 
                return true;

            return false;
        }
    }


        
    public static bool IsUKLicense
    {
        get
        {
            if (!SafeParseBoolString(Metadata.Get("Metadata/Settings.IsUKLicense"), false))
                return false;

            try
            {
                string[] countryIDs = SafeParseArray(Metadata.Get("Metadata/Settings.UKLicense_CountryIDs"));

                IPLocation ipLocation = IPLocation.GetByIP(HttpContext.Current.Request.GetRealUserAddress());
                return countryIDs.Contains(ipLocation.CountryID.ToString(CultureInfo.InvariantCulture));
            }
            catch
            {
                return false;
            }
        }
    }

    public static bool IsOMAllowedonUKLicense
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.IsOMAllowedonUKLicense"), true);
        }
    }    

    public static string PugglePay_UserMessage
    {
        get
        {
            return Metadata.Get("Metadata/Settings.PugglePay_UserMessage");
        }
    }

    public static bool Deposit_SkipPaymentMethodCheck
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings/Deposit.SkipPaymentMethodCheck"), false);
        }
    }

    public static bool Withdraw_SkipPaymentMethodCheck
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings/Withdraw.SkipPaymentMethodCheck"), false);
        }
    }

    public static bool Switch_GoogleAnalystics
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.Switch_GoogleAnalystics"), true);
        }
    }
    public static bool DisableUpdateAffiliateCode
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.DisableUpdateAffiliateCode"), true);
        }
    }
    public static bool IsValidateAntiForgeryToken
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.IsValidateAntiForgeryToken"), false);
        }
    }

    public static string Email_ValidateAntiForgeryTokenReceiver
    {
        get
        {
            return Metadata.Get("Metadata/Settings.Email_ValidateAntiForgeryTokenReceiver");
        }
    }

    public static string Password_GlobalExpiryTime
    {
        get
        {
            return Metadata.Get("Metadata/Settings.Password_GlobalExpiryTime");
        }
    }

    public static bool Password_GlobalExpiry_Enabled
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.Password_GlobalExpiry_Enabled"), false);
        }
    }

    public static bool EnableDKRegisterWithoutNemID
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings/DKLicense.EnableDKRegisterWithoutNemID"), false);
        }
    }

    public static bool CheckedNemIDNotProvidedRole
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings/DKLicense.CheckedNemIDNotProvidedRole"), false);
        }
    }

    public static bool EnableContract
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.EnableContract"), false);
        }
    }

    public static int CombinedJsPosition
    {
        get
        {
            int position = 0;
            int.TryParse(Metadata.Get("Metadata/Settings.CombinedJsPosition"), out position);
            if (position > 2 || position < 0) position = 0;
            return position;
        }
    }

    public static bool EnableAsyncCombinedJs
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.EnableAsyncCombinedJs"), false);
        }
    }

    public static bool SecondStepsAuthenticationEnabled
    {
        get
        {
            return SafeParseBoolString(Metadata.Get("Metadata/Settings.SecondStepsAuthenticationEnabled"), false);
        }
    }

    #region MOBILE V2 SETTINGS

    public class MobileV2
    {

        public static bool IsRegisterV2Enabled
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/V2.EnableRegisterV2"), false);
            }
        }

        public static bool IsLoginV2FormEnabled
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/V2.EnableLoginV2Form"), false);
            }
        }

        public static bool IsV2DepositProcessEnabled
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/V2.EnableV2DepositProcess"), false);
            }
        }

        public static bool IsV2HomePageEnabled
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/V2.EnableV2HomePage"), false);
            }
        }

        public static bool IsV2MenuEnabled
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/V2.EnableV2Menu"), false);
            }
        }

        public static bool IsFooterCopyrightHidden
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/V2.HideFooterCopyright"), false);
            }
        }

        public static bool IsHomeRegisterButtonHidden
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/V2.HideHomeRegisterButton"), false);
            }
        }

        public static bool IsLanguageSelectorOnHomePageHidden
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/V2.HideLanguageSelectorOnHomePage"), false);
            }
        }

        public static bool IsV2ProfileEnabled 
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/V2.EnableV2Profile"), false);
            }
        }
    }
    #endregion

    #region Limitation
    public static class Limitation
    {
        public static bool Deposit_MultipleSet_Enabled
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Limitation.Deposit_MultipleSet_Enabled"), false);
            }
        }
    }
    #endregion

    public static class Session
    {
        public static bool SecondFactorAuthenticationEnabled
        {
            get {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings/Session.SecondFactorAuthenticationEnabled"), false);
            }
        }
    }
}