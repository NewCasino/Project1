<%@ WebHandler Language="C#" Class="_everleafpoker_login" %>

using System;
using System.Web;
using System.Linq;
using System.Xml.Linq;
using System.Collections.Generic;

using CM.State;
using GmCore;
using GamMatrixAPI;
using CM.db.Accessor;
using CM.Sites;
using CM.db;

#region XML
/*
<message method="getPlayerInfos">
  <TCAccepted>2012-05-30 06:40:50</TCAccepted>
  <iID>1035662</iID>
  <cNick>asdddd01</cNick>
  <cPassword>e10adc3949ba59abbe56e057f20f883e</cPassword>
  <cLoginIP>124.233.3.10</cLoginIP>
  <dLoginTime>0000-00-00 00:00:00</dLoginTime>
  <iGender>1</iGender>
  <iStatus>2</iStatus>
  <AFF_iID></AFF_iID>
  <iActiv>1</iActiv>
  <iAvatar></iAvatar>
  <iTimeOffset></iTimeOffset>
  <cValidationCode></cValidationCode>
  <iDisconnectProtects>2</iDisconnectProtects>
  <iValidated>1</iValidated>
  <iLegitimated>0</iLegitimated>
  <iHousePlayer>0</iHousePlayer>
  <iFirstDeposit>0</iFirstDeposit>
  <dFirstDeposit>0000-00-00 00:00:00</dFirstDeposit>
  <bHideFromPlayers>0</bHideFromPlayers>
  <dLastOnline>0000-00-00 00:00:00</dLastOnline>
  <cUserName>jerrywang</cUserName>
  <CAS_iID>388</CAS_iID>
  <dLastBuddyUpdate>0000-00-00 00:00:00</dLastBuddyUpdate>
  <cEmail>wj@everymatrix.com</cEmail>
  <iPicture>0</iPicture>
  <cClientInfoText>test, China (CHN)</cClientInfoText>
  <ACT_iID>6</ACT_iID>
  <bMustChangePassword>0</bMustChangePassword>
  <iRating>1</iRating>
  <iRatingCommunity>0</iRatingCommunity>
  <fBBWon>0</fBBWon>
  <fOppRating>0</fOppRating>
  <iGamesPlayed>0</iGamesPlayed>
  <dLastLogin></dLastLogin>
  <WSH_iID>1035662</WSH_iID>
  <WSH_IDString>83BFF09D7AF0AAB4D5A66C3B187080CD</WSH_IDString>
  <WSH_dValidTill>2012-05-31 07:13:38</WSH_dValidTill>
  <WSH_cIP>124.233.3.10</WSH_cIP>
  <WSH_FSS_iID>19584863</WSH_FSS_iID>
  <WSH_CAS_iID>388</WSH_CAS_iID>
  <cFirstName>Jerry</cFirstName>
  <cLastName>Wang</cLastName>
  <cStreet>test, test</cStreet>
  <cState></cState>
  <cCity>test</cCity>
  <cCountry>China (CHN)</cCountry>
  <cZip>1111111</cZip>
  <cPhone>+861111111111111</cPhone>
  <cPassCode></cPassCode>
  <cTitle>Mr.</cTitle>
  <cNewsLetter>1</cNewsLetter>
  <LNG_iID>2</LNG_iID>
  <dLastChange>2012-05-30 06:40:50</dLastChange>
  <dOpened>2012-05-30 06:40:50</dOpened>
  <cBonusCode></cBonusCode>
  <iBonusPoints></iBonusPoints>
  <dBirthDate>1979-12-14</dBirthDate>
  <cHeardAbout></cHeardAbout>
  <iCritical></iCritical>
  <cRegistrationDomain>www.everleafgaming.c</cRegistrationDomain>
  <cGroup>D-Rating</cGroup>
  <dValidationTime>2012-05-30 06:40:50</dValidationTime>
  <dLegitimationTime>0000-00-00 00:00:00</dLegitimationTime>
  <dAffiliateTime>0000-00-00 00:00:00</dAffiliateTime>
  <dHouseplayerTime>0000-00-00 00:00:00</dHouseplayerTime>
  <cRegisterIP>85.9.28.130</cRegisterIP>
  <iValidatedbyPCC>0</iValidatedbyPCC>
  <iWerbeMails>0</iWerbeMails>
  <cPhone2></cPhone2>
  <cPhoneTime></cPhoneTime>
  <cPhoneTime2></cPhoneTime2>
  <iPostalMail>1</iPostalMail>
  <iTournamentMails>1</iTournamentMails>
  <cGEOCountry>ROU</cGEOCountry>
  <cCustomInfo1></cCustomInfo1>
  <cCustomInfo2></cCustomInfo2>
  <cCustomInfo3></cCustomInfo3>
  <iSubSkin>0</iSubSkin>
  <cPaymentCode></cPaymentCode>
  <BON_iID_Rake>0</BON_iID_Rake>
  <dTCAccepted>2012-05-30 06:40:50</dTCAccepted>
  <USD_ACC_iID>16820026</USD_ACC_iID>
  <USD>0</USD>
  <PM_ACC_iID>16820027</PM_ACC_iID>
  <PM>1000</PM>
  <RPP_ACC_iID>16820028</RPP_ACC_iID>
  <RPP>0</RPP>
  <PPP_ACC_iID>16820029</PPP_ACC_iID>
  <PPP>0</PPP>
  <EUR_ACC_iID>16820030</EUR_ACC_iID>
  <EUR>0</EUR>
  <RM_ACC_iID>16820030</RM_ACC_iID>
  <RM>0</RM>
  <iIsAffiliateID>0</iIsAffiliateID>
  <iMasterAffiliateID>0</iMasterAffiliateID>
</message>
             */
#endregion

public class _everleafpoker_login : IHttpHandler {
    
    public void ProcessRequest (HttpContext context) {
        CustomProfile.Current.Init(context);

        string sessionID = context.Request.QueryString["sessionid"];
        try
        {
            if (!string.IsNullOrEmpty(sessionID))
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    EverleafNetworkAPIRequest request = new EverleafNetworkAPIRequest()
                    {
                        GetPlayerInfos = true,
                        GetPlayerInfosQUERYTYPE = "SESSIONID",
                        GetPlayerInfosQUERYVALUE = new Dictionary<string, string>()
                    };
                    request.GetPlayerInfosQUERYVALUE.Add("SESSIONID", sessionID);
                    request = client.SingleRequest<EverleafNetworkAPIRequest>(request);

                    XDocument xDoc = XDocument.Parse(request.GetPlayerInfosResponse);
                    string username = xDoc.Root.Element("cUserName").Value;
                    string ip = xDoc.Root.Element("cLoginIP").Value;

                    if (!ProfileCommon.Current.IsAuthenticated ||
                        !string.Equals(ProfileCommon.Current.UserName, username, StringComparison.InvariantCultureIgnoreCase))
                    {
                        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                        cmUser user = ua.GetByUsername(SiteManager.Current.DomainID, username);
                        if (user != null)
                        {
                            CustomProfile.LoginResult result = CustomProfile.Current.ExternalLogin(SiteManager.Current, user.ID, ip);
                            if (result != CustomProfile.LoginResult.Success)
                            {
                                Logger.Error("Everleaf Poker", "Login failed {0}", sessionID);
                            }
                        }
                    }
                }
            }
        }
        catch (Exception ex)
        {
            Logger.Exception(ex);
        }

        string dest = context.Request.QueryString["dest"];
        if (!string.IsNullOrWhiteSpace(dest))
        {
            string url;
            switch (dest.ToUpperInvariant())
            {
                case "CASHIER":
                case "DEPOSIT":
                    url = "/Deposit/?_sid={0}";
                    break;

                case "CASHOUT":
                    url = "/Withdraw/?_sid={0}";
                    break;

                case "FORGOTPWD":
                    url = "/ForgotPassword";
                    break;

                case "HELP_FAQ":
                    url = "/Help/?_sid={0}";
                    break;

                case "SIGNUP":
                    url = "/Register";
                    break;

                case "INFO_ABOUTUS":
                    url = "/AboutUs/?_sid={0}";
                    break;

                case "MYACCOUNT_CHANGEPWD":
                    url = "/ChangePwd/?_sid={0}";
                    break;

                case "MYACCOUNT_CASHHISTORY":
                    url = "/AccountStatement/?_sid={0}";
                    break;

                case "GOTOMYACCOUNT":
                    url = "/Profile/?_sid={0}";
                    break;

                case "NEWS_TOURNAMENTS":
                    url = "/Poker/Tournaments/EverleafPoker?_sid={0}";
                    break;

                default:
                    url = "/";
                    break;          
            }

            context.Response.Redirect( string.Format( url, HttpUtility.UrlEncode(CustomProfile.Current.SessionID) ));
        }
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

}