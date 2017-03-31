using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.IO;
using System.Resources;
using System.Data;
using System.Data.Sql;
using System.Data.SqlClient;
using System.Xml.Linq;


namespace ResourceMigration
{

    class Program
    {
        private sealed class ResxLangInfo
        {
            public string GenericLangFile { get; set; }
            public string SpericalLangFile { get; set; }
        }

        //public const string SOURCE_BASE_DIR = @"L:\GameMatrix\CMS\CmsWeb\";
        //public const string DESTINATION_BASE_DIR = @"L:\NewCms\GamMatrix.CMS\Views\Shared\";
        public const string SOURCE_BASE_DIR = @"G:\共享\Adjara\Translations for Every Matrix\Translation1\Translation1\Resources\";
        public const string DESTINATION_BASE_DIR = @"G:\共享\Adjara\Shared\";
        public const string DB_CONNECTION_STR = @"Data Source=10.0.1.198;Initial Catalog=cm;User ID=sa;Password=abc123";

        public static readonly string[] ENTR;

        static void Main(string[] args)
        {
            CopyBingo();
            CopyCasino();

            CopyAvailableBonus();
            //CopyGames();
            //CopyGmCoreMessage();
            //CopyCountries();
            CopyDepositLimit();
            CopyDeposit();
            CopyChangePwd();
            CopySelfExclusion();
            CopyProfile();
            CopyForgotPwd();
            CopyBuddyTransfer();
            CopyTransfer();
            CopyAccountStatement();
            CopyPendingWithdrawals();
            CopyWithdraw();
            CopyDeposit();
            CopyPaymentMethods();
            CopyAccountBox();
            CopyBalance();
            CopyMasterLogin();
            CopyRegisterComplete();
            CopySecurityQuestion();
            CopyCurrency();
            CopyTitle();
            CopyRegister();
            

            Console.WriteLine("Done!");
            Console.ReadLine();
        }

        private static void CopyGames()
        {
            XDocument doc = XDocument.Load(@"G:\CMS\Cms\CmsWeb\Games\NetEnt\en.xml");
            var games = doc.Descendants("game");
            foreach (var game in games)
            {
                string id = game.Element("id").Value;
                string title = game.Element("title").Value;
                string category = game.Element("category").Value;
                string description = game.Element("description").Value;

                CreateMetadata(string.Format(@"Metadata\Casino\NetEnt\CTXM\{0}", id));
                Directory.CreateDirectory(string.Format(@"Metadata\Casino\NetEnt\CTXM\{0}", id));

                string destPath = string.Format(@"Metadata\Casino\Games\NetEnt\{0}\.ID", id);
                using (StreamWriter sw = new StreamWriter(DESTINATION_BASE_DIR + destPath, false, Encoding.UTF8))
                {
                    sw.Write(id);
                    sw.Flush();
                }
            }
        }

        private static void CopyBingo()
        {
            CopyResource(@"opCommon\Bingo\App_LocalResources\BingoRooms.ascx.resx"
                , "Anonymous_User"
                , @"Bingo\Home\_Rooms_ascx\.Anonymous_User"
                );
            CopyResource(@"opCommon\Bingo\App_LocalResources\BingoRooms.ascx.resx"
                , "Anonymous_User"
                , @"Bingo\Home\_Rooms_ascx\.Anonymous_User"
                );
            CopyResource(@"opCommon\Bingo\App_LocalResources\BingoRooms.ascx.resx"
                , "BingoRooms"
                , @"Bingo\Home\_Rooms_ascx\.BingoRooms"
                );
            CopyResource(@"opCommon\Bingo\App_LocalResources\BingoRooms.ascx.resx"
                , "Button_Play"
                , @"Bingo\Home\_Rooms_ascx\.Button_Play"
                );
            CopyResource(@"opCommon\Bingo\App_LocalResources\BingoRooms.ascx.resx"
                , "Cost"
                , @"Bingo\Home\_Rooms_ascx\.Cost"
                );
            CopyResource(@"opCommon\Bingo\App_LocalResources\BingoRooms.ascx.resx"
                , "Jackpot"
                , @"Bingo\Home\_Rooms_ascx\.Jackpot"
                );
            CopyResource(@"opCommon\Bingo\App_LocalResources\BingoRooms.ascx.resx"
                , "Jackpotin53"
                , @"Bingo\Home\_Rooms_ascx\.Jackpotin53"
                );
            CopyResource(@"opCommon\Bingo\App_LocalResources\BingoRooms.ascx.resx"
                , "Num"
                , @"Bingo\Home\_Rooms_ascx\.Num"
                );
            CopyResource(@"opCommon\Bingo\App_LocalResources\BingoRooms.ascx.resx"
                , "Play"
                , @"Bingo\Home\_Rooms_ascx\.Play"
                );
            CopyResource(@"opCommon\Bingo\App_LocalResources\BingoRooms.ascx.resx"
                , "Players"
                , @"Bingo\Home\_Rooms_ascx\.Players"
                );
            CopyResource(@"opCommon\Bingo\App_LocalResources\BingoRooms.ascx.resx"
                , "Price"
                , @"Bingo\Home\_Rooms_ascx\.Price"
                );
            CopyResource(@"opCommon\Bingo\App_LocalResources\BingoRooms.ascx.resx"
                , "Room"
                , @"Bingo\Home\_Rooms_ascx\.Room"
                );
            CopyResource(@"opCommon\Bingo\App_LocalResources\BingoRooms.ascx.resx"
                , "Start"
                , @"Bingo\Home\_Rooms_ascx\.Start"
                );
            CopyResource(@"opCommon\Bingo\App_LocalResources\BingoRooms.ascx.resx"
                , "Started"
                , @"Bingo\Home\_Rooms_ascx\.Started"
                );
            CopyResource(@"opCommon\Bingo\App_LocalResources\BingoRooms.ascx.resx"
                , "Type"
                , @"Bingo\Home\_Rooms_ascx\.Type"
                );
            CopyResource(@"opCommon\Bingo\App_LocalResources\BingoRooms.ascx.resx"
                , "Winnings"
                , @"Bingo\Home\_Rooms_ascx\.Winnings"
                );
        }

        private static void CopyCasino()
        {
            CopyResource(@"opCommon\Casino\App_LocalResources\FullCasino.ascx.resx"
                , "Menu_Fullscreen"
                , @"Casino\Loader\_Loader_ascx\.Fullscreen"
                );
            CopyResource(@"opCommon\Casino\App_LocalResources\FullCasino.ascx.resx"
                , "Button_GameRules"
                , @"Casino\Loader\_Loader_ascx\.GameRules"
                );
            CopyResource(@"opCommon\Casino\App_LocalResources\FullCasino.ascx.resx"
                , "Button_Real_money"
                , @"Casino\Loader\_Loader_ascx\.PlayWithRealMoney"
                );
            CopyResource(@"opCommon\Casino\App_LocalResources\FullCasino.ascx.resx"
                , "Button_Fun"
                , @"Casino\Loader\_Loader_ascx\.PlayForFun"
                );
            CopyResource(@"opSys\App_LocalResources\FullScreenGame.aspx.resx"
                , "Game_Note"
                , @"Casino\Loader\_Loader_ascx\.AnonymousMessage"
                );

            // Jackpots
            CopyResource(@"opCommon\Casino\App_LocalResources\JackpotListEx.ascx.resx"
                , "Button_PlayNow"
                , @"Casino\Home\_JackpotRotator_ascx\.PlayNow"
                );
            CopyResource(@"opCommon\Casino\App_LocalResources\JackpotListEx.ascx.resx"
                , "Header_Text"
                , @"Casino\Home\_JackpotRotator_ascx\.CurrentJackpots"
                );

            // Winners
            CopyResource(@"opCommon\Casino\App_LocalResources\WinnersNow.ascx.resx"
                , "Button_PlayNow"
                , @"Casino\Home\_LastWinners_ascx\.WinnersRightNow"
                );

            // FPP
            CopyResource(@"opCommon\Casino\App_LocalResources\PlayerPoint.ascx.resx"
                , "claim"
                , @"Casino\Home\_NetEntFPP_ascx\.Claim"
                );
            CopyResource(@"opCommon\Casino\App_LocalResources\PlayerPoint.ascx.resx"
                , "learn_more"
                , @"Casino\Home\_NetEntFPP_ascx\.Learn_More"
                );
            CopyResource(@"opCommon\Casino\App_LocalResources\PlayerPoint.ascx.resx"
                , "cash_rewards"
                , @"Casino\Home\_NetEntFPP_ascx\.Cash_Rewards"
                );
        }

        private static void CopyAvailableBonus()
        {
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "Anonymous_Message"
                , @"AvailableBonus\_Anonymous_aspx\.Message"
                );
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "AvailableBonusTitle"
                , @"AvailableBonus\_Index_aspx\.HEAD_TEXT"
                );
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "Error_GeneralMessage"
                , @"AvailableBonus\_Error_aspx\.Message"
                );
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "CasinoBonus"
                , @"AvailableBonus\_Index_aspx\.Casino_Bonus"
                );
            /*
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "BonusType"
                , @"AvailableBonus\_Index_aspx\.Bonus_Type"
                );
             * */
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "BonusAmount"
                , @"AvailableBonus\_Index_aspx\.Bonus_Amount"
                );
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "RemainingWagering"
                , @"AvailableBonus\_Index_aspx\.Remaining_Wagering"
                );
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "ExpiryDate"
                , @"AvailableBonus\_Index_aspx\.Expiry_Date"
                );
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "BonusCode"
                , @"AvailableBonus\_Index_aspx\.Bonus_Code"
                );
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "BonusName"
                , @"AvailableBonus\_Index_aspx\.Bonus_Name"
                );
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "BonusGrantedDate"
                , @"AvailableBonus\_Index_aspx\.Bonus_Granted_Date"
                );
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "EmptyList"
                , @"AvailableBonus\_Index_aspx\.No_Bonus"
                );
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "CasinoFPP"
                , @"AvailableBonus\_Index_aspx\.Casino_FPP"
                );
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "FPPPoints"
                , @"AvailableBonus\_Index_aspx\.Casino_FPP_Points"
                );
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "ExchangeAmount"
                , @"AvailableBonus\_Index_aspx\.Casino_FPP_Exchange_Amount"
                );
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "Claim"
                , @"AvailableBonus\_Index_aspx\.Button_Claim"
                );
            
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "FPPNote"
                , @"AvailableBonus\_Index_aspx\.Casino_FPP_Notes"
                );
            /*
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "CasinoWalletBonusInfo"
                , @"AvailableBonus\_Index_aspx\.Enter_Bonus_Code"
                );
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "Status"
                , @"AvailableBonus\_Index_aspx\.Status"
                );
            
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "ConfiscateAllWarning"
                , @"AvailableBonus\_Index_aspx\.Confiscate_All_Warning"
                );
            CopyResource(@"opCommon\App_LocalResources\AvailableBonus.ascx.resx"
                , "ForfeitWarning"
                , @"AvailableBonus\_Index_aspx\.Forfeit_Warning"
                );
             * */
        }
        

        
        private static void CopyGmCoreMessage()
        {
            XDocument doc = XDocument.Load("https://admin.gammatrix.com/ErrorCodeList.xml");
            foreach (var c in doc.Descendants("Error"))
            {
                string code = c.Element("Code").Value;
                string userMessage = c.Element("UserMessage").Value;

                CreateMetadata( string.Format( @"Metadata\GmCoreErrorCodes\{0}", code.Replace('-', '_')) );
                string destPath = string.Format(@"Metadata\GmCoreErrorCodes\{0}\.UserMessage", code.Replace('-', '_'));
                //CopyResource(@"App_GlobalResources\GmCoreMessages.resx"
                //    , code
                //    , destPath
                //    );
                using (StreamWriter sw = new StreamWriter(DESTINATION_BASE_DIR + destPath, false, Encoding.UTF8))
                {
                    sw.Write(userMessage);
                    sw.Flush();
                }
            }
        }

        private static void CopyDepositLimit()
        {
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "Anonymous_Message"
                , @"DepositLimitation\_Anonymous_ascx\.Message"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "Header"
                , @"DepositLimitation\_Index_aspx\.HEAD_TEXT"
                );

            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "Description"
                , @"DepositLimitation\_InputView_ascx\.Introduction"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "Field_Currency"
                , @"DepositLimitation\_InputView_ascx\.Currency_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "ERR_CurrencyIsMissing"
                , @"DepositLimitation\_InputView_ascx\.Currency_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "Field_Amount"
                , @"DepositLimitation\_InputView_ascx\.Amount_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "ERR_AmountIsMissing"
                , @"DepositLimitation\_InputView_ascx\.Amount_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "Field_ExpirationDate"
                , @"DepositLimitation\_InputView_ascx\.ExpirationDate_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "Field_Period"
                , @"DepositLimitation\_InputView_ascx\.Period_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "ERR_PeriodIsMissing"
                , @"DepositLimitation\_InputView_ascx\.Period_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "Field_ValidFrom"
                , @"DepositLimitation\_InputView_ascx\.ValidFrom_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "PeriodDaily"
                , @"DepositLimitation\_InputView_ascx\.Period_Daily"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "PeriodMonthly"
                , @"DepositLimitation\_InputView_ascx\.Period_Monthly"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "PeriodWeekly"
                , @"DepositLimitation\_InputView_ascx\.Period_Weekly"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "BtnSubmit"
                , @"DepositLimitation\_InputView_ascx\.Button_Submit"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "BtnRemove"
                , @"DepositLimitation\_InputView_ascx\.Button_Remove"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "BtnChange"
                , @"DepositLimitation\_InputView_ascx\.Button_Change"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "RemovedLimitDescription"
                , @"DepositLimitation\_InputView_ascx\.Limit_Removed"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "ChangedLimitDescription"
                , @"DepositLimitation\_InputView_ascx\.Limit_Scheduled"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSetDepositLimit.ascx.resx"
                , "MSG_SureToRemoveLimit"
                , @"DepositLimitation\_InputView_ascx\.Confirmation_Message"
                );
        }

        private static void CopySelfExclusion()
        {
            CopyResource(@"opCommon\App_LocalResources\RgSelfExclusion.ascx.resx"
                , "Anonymous_Message"
                , @"SelfExclusion\_Anonymous_ascx\.Message"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSelfExclusion.ascx.resx"
                , "Header"
                , @"SelfExclusion\_Index_aspx\.HEAD_TEXT"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSelfExclusion.ascx.resx"
                , "OptionsToChoose"
                , @"SelfExclusion\_InputView_ascx\.Options_To_Choose"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSelfExclusion.ascx.resx"
                , "SevenDaysPeriod"
                , @"SelfExclusion\_InputView_ascx\.Option1"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSelfExclusion.ascx.resx"
                , "SixMonthsPeriod"
                , @"SelfExclusion\_InputView_ascx\.Option2"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSelfExclusion.ascx.resx"
                , "SevenDaysOption"
                , @"SelfExclusion\_InputView_ascx\.SevenDaysOption"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSelfExclusion.ascx.resx"
                , "SevenDaysOptionDescription"
                , @"SelfExclusion\_InputView_ascx\.SevenDaysOptionDescription"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSelfExclusion.ascx.resx"
                , "SixMonthsOption"
                , @"SelfExclusion\_InputView_ascx\.SixMonthsOption"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSelfExclusion.ascx.resx"
                , "SixMonthsOptionDescription"
                , @"SelfExclusion\_InputView_ascx\.SixMonthsOptionDescription"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSelfExclusion.ascx.resx"
                , "BtnSubmit"
                , @"SelfExclusion\_InputView_ascx\.Button_Submit"
                );
            CopyResource(@"opCommon\App_LocalResources\RgSelfExclusion.ascx.resx"
                , "MSG_SureToSelfExclude"
                , @"SelfExclusion\_InputView_ascx\.Confirmation_Message"
                );
        }

        private static void CopyChangePwd()
        {
            CopyResource(@"opCommon\App_LocalResources\ChangePwd.ascx.resx"
                , "Title"
                , @"ChangePwd\_Index_aspx\.HEAD_TEXT"
                );
            CopyResource(@"opCommon\App_LocalResources\ChangePwd.ascx.resx"
                , "Button_Save"
                , @"ChangePwd\_InputView_ascx\.Button_Save"
                );
            CopyResource(@"opCommon\App_LocalResources\ChangePwd.ascx.resx"
                , "OldPassword"
                , @"ChangePwd\_InputView_ascx\.OldPassword_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\ChangePwd.ascx.resx"
                , "OldPassword_Missing"
                , @"ChangePwd\_InputView_ascx\.OldPassword_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\ChangePwd.ascx.resx"
                , "NewPassword"
                , @"ChangePwd\_InputView_ascx\.NewPassword_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\ChangePwd.ascx.resx"
                , "NewPassword_Invalid"
                , @"ChangePwd\_InputView_ascx\.NewPassword_Invalid"
                );
            CopyResource(@"opCommon\App_LocalResources\ChangePwd.ascx.resx"
                , "NewPassword_Missing"
                , @"ChangePwd\_InputView_ascx\.NewPassword_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\ChangePwd.ascx.resx"
                , "PasswordRep"
                , @"ChangePwd\_InputView_ascx\.RepeatPassword_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\ChangePwd.ascx.resx"
                , "PasswordRep_Missing"
                , @"ChangePwd\_InputView_ascx\.RepeatPassword_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\ChangePwd.ascx.resx"
                , "PasswordRep_NotCorrect"
                , @"ChangePwd\_InputView_ascx\.RepeatPassword_NotMatch"
                );
            CopyResource(@"opCommon\App_LocalResources\ChangePwd.ascx.resx"
                , "Anonymous_Message"
                , @"ChangePwd\_Anonymous_ascx\.Message"
                );
            CopyResource(@"opCommon\App_LocalResources\ChangePwd.ascx.resx"
                , "Password_Changed"
                , @"ChangePwd\_Success_ascx\.Message"
                );
        }

        private static void CopyProfile()
        {
            CopyResource(@"opCommon\App_LocalResources\Profile.ascx.resx"
                , "UpdateProfile"
                , @"Profile\_InputView_ascx\.Button_Update"
                );
            CopyResource(@"opCommon\App_LocalResources\Profile.ascx.resx"
                , "UserId"
                , @"Profile\_InputView_ascx\.UserID_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Profile.ascx.resx"
                , "Success_Message"
                , @"Profile\_Success_ascx\.Message"
                );
            CopyResource(@"opCommon\App_LocalResources\Profile.ascx.resx"
                , "ProfileTitle"
                , @"Profile\_Index_aspx\.HEAD_TEXT"
                );
            CopyResource(@"opCommon\App_LocalResources\Profile.ascx.resx"
                , "Anonymous_Message"
                , @"Profile\_Anonymous_ascx\.Message"
                );
        }

        private static void CopyForgotPwd()
        {
            CopyResource(@"opCommon\App_LocalResources\LostPassword.ascx.resx"
                , "EnterEmailGetWithInstructions"
                , @"ForgotPassword\_Index_aspx\.Message"
                );
            CopyResource(@"opCommon\App_LocalResources\LostPassword.ascx.resx"
                , "EmailAddress"
                , @"ForgotPassword\_Index_aspx\.Email_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\LostPassword.ascx.resx"
                , "Email_Missing"
                , @"ForgotPassword\_Index_aspx\.Email_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\LostPassword.ascx.resx"
                , "Submit"
                , @"ForgotPassword\_Index_aspx\.Button_Submit"
                );
            CopyResource(@"opCommon\App_LocalResources\LostPassword.ascx.resx"
                , "EmailSent"
                , @"ForgotPassword\_EmailSent_aspx\.Success_Message"
                );
            CopyResource(@"opCommon\App_LocalResources\LostPassword.ascx.resx"
                , "EmailSentIfNotArrive"
                , @"ForgotPassword\_EmailSent_aspx\.Info_Message"
                );
            CopyResource(@"opCommon\App_LocalResources\LostPassword.ascx.resx"
                , "EmailSendFailed"
                , @"ForgotPassword\_Error_aspx\.Message"
                );

            CopyResource(@"opCommon\App_LocalResources\LostPassword.ascx.resx"
                , "NewPassword"
                , @"ForgotPassword\_ChangePassword_aspx\.NewPassword_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\LostPassword.ascx.resx"
                , "NewPassword_Missing"
                , @"ForgotPassword\_ChangePassword_aspx\.NewPassword_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\LostPassword.ascx.resx"
                , "NewPassword_Invalid"
                , @"ForgotPassword\_ChangePassword_aspx\.NewPassword_Invalid"
                );
            CopyResource(@"opCommon\App_LocalResources\LostPassword.ascx.resx"
                , "ConfirmPassword"
                , @"ForgotPassword\_ChangePassword_aspx\.ConfirmPassword_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\LostPassword.ascx.resx"
                , "ConfirmPassword_Missing"
                , @"ForgotPassword\_ChangePassword_aspx\.ConfirmPassword_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\LostPassword.ascx.resx"
                , "ConfirmPassword_Mismatch"
                , @"ForgotPassword\_ChangePassword_aspx\.ConfirmPassword_Mismatch"
                );
            CopyResource(@"opCommon\App_LocalResources\LostPassword.ascx.resx"
                , "SetPasswordButton"
                , @"ForgotPassword\_ChangePassword_aspx\.Button_SetPassword"
                );
            CopyResource(@"opCommon\App_LocalResources\LostPassword.ascx.resx"
                , "LinkExpiredOrInvalid"
                , @"ForgotPassword\_InvalidLink_aspx\.Message"
                );
            CopyResource(@"opCommon\App_LocalResources\LostPassword.ascx.resx"
                , "SuccessfullyChangedPassword"
                , @"ForgotPassword\_PasswordChanged_aspx\.Message"
                );

            /*
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Field_Captcha"
                , @"Components\_Captcha_ascx\.Captcha_Label"
                );
             * */
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Captcha_Missing"
                , @"Components\_Captcha_ascx\.Captcha_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Captcha_Invalid"
                , @"Components\_Captcha_ascx\.Captcha_Invalid"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Captcha_Unclear"
                , @"Components\_Captcha_ascx\.Captcha_Hint"
                );

        }

        private static void CopyBuddyTransfer()
        {
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Header"
                , @"BuddyTransfer\_Index_aspx\.HEAD_TEXT"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Anonymous_Message"
                , @"BuddyTransfer\_Anonymous_aspx\.Message"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Error_UserNotVerified"
                , @"BuddyTransfer\_IdentityNotVerified_aspx\.Message"
                );
            
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Button_Continue"
                , @"BuddyTransfer\_Index_aspx\.Button_Continue"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Button_Continue"
                , @"BuddyTransfer\_Index_aspx\.Button_Continue"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Button_Confirm"
                , @"BuddyTransfer\_Index_aspx\.Button_Confirm"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Button_Back"
                , @"BuddyTransfer\_Index_aspx\.Button_Back"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Button_Transfer"
                , @"BuddyTransfer\_Index_aspx\.Button_Transfer"
                );

            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Validation_FriendMissing"
                , @"BuddyTransfer\_SelectFriend_ascx\.Friend_Select_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Field_SelectFriend"
                , @"BuddyTransfer\_SelectFriend_ascx\.Friend_Select"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Radio_ChooseFriend"
                , @"BuddyTransfer\_SelectFriend_ascx\.Tab_ChooseFriend"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Radio_FindFriend"
                , @"BuddyTransfer\_SelectFriend_ascx\.Tab_FindFriend"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Field_Username"
                , @"BuddyTransfer\_SelectFriend_ascx\.Friend_Username_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Validation_FriendMissing2"
                , @"BuddyTransfer\_SelectFriend_ascx\.Friend_Username_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Field_Email"
                , @"BuddyTransfer\_SelectFriend_ascx\.Friend_Email_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Validation_EmailMissing"
                , @"BuddyTransfer\_SelectFriend_ascx\.Friend_Email_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Error_EmailIncorrect"
                , @"BuddyTransfer\_SelectFriend_ascx\.Friend_UsernameOrEmail_Incorrect"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Error_FriendInactive"
                , @"BuddyTransfer\_SelectFriend_ascx\.Friend_Email_Inactive"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Error_FriendNotVerified"
                , @"BuddyTransfer\_SelectFriend_ascx\.Friend_NotVerified"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Error_TransferToSelf"
                , @"BuddyTransfer\_SelectFriend_ascx\.Friend_Invalid"
                );

            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Field_FromAccount"
                , @"BuddyTransfer\_Prepare_ascx\.DebitGammingAccount_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Validation_FromAccountMissing"
                , @"BuddyTransfer\_Prepare_ascx\.DebitGammingAccount_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Field_ToAccount"
                , @"BuddyTransfer\_Prepare_ascx\.CreditGammingAccount_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Validation_ToAccountMissing"
                , @"BuddyTransfer\_Prepare_ascx\.CreditGammingAccount_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Field_Amount"
                , @"BuddyTransfer\_Prepare_ascx\.CurrencyAmount_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Validation_IsufficientFunds"
                , @"BuddyTransfer\_Prepare_ascx\.CurrencyAmount_Insufficient"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Validation_AmountLimits"
                , @"BuddyTransfer\_Prepare_ascx\.CurrencyAmount_OutsideRange"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Validation_AmountMissing"
                , @"BuddyTransfer\_Prepare_ascx\.CurrencyAmount_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Field_Username"
                , @"BuddyTransfer\_Prepare_ascx\.FriendUsername_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Field_FullName"
                , @"BuddyTransfer\_Prepare_ascx\.FriendFullname_Label"
                );
            
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Confirm_DebitItem"
                , @"BuddyTransfer\_Confirmation_ascx\.DebitAccount"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Confirm_CreditItem"
                , @"BuddyTransfer\_Confirmation_ascx\.CreditAccount"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Error_Message"
                , @"BuddyTransfer\_Error_aspx\.Message"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Confirm_DebitItem"
                , @"BuddyTransfer\_Receipt_aspx\.DebitAccount"
                );
            CopyResource(@"opCommon\App_LocalResources\P2PTransfer.ascx.resx"
                , "Confirm_CreditItem"
                , @"BuddyTransfer\_Receipt_aspx\.CreditAccount"
                );
        }

        private static void CopyTransfer()
        {
            CopyResource(@"opCommon\App_LocalResources\Transfer.ascx.resx"
                , "Header_Transfer"
                , @"Transfer\_Index_aspx\.HEAD_TEXT"
                );
            CopyResource(@"opCommon\App_LocalResources\Transfer.ascx.resx"
                , "Anonymous_Message"
                , @"Transfer\_Anonymous_ascx\.Message"
                );
            CopyResource(@"opCommon\App_LocalResources\Transfer.ascx.resx"
                , "Field_FromAccount"
                , @"Transfer\_Prepare_ascx\.DebitGammingAccount_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Transfer.ascx.resx"
                , "Validation_FromAccountMissing"
                , @"Transfer\_Prepare_ascx\.DebitGammingAccount_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\Transfer.ascx.resx"
                , "Field_ToAccount"
                , @"Transfer\_Prepare_ascx\.CreditGammingAccount_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Transfer.ascx.resx"
                , "Validation_ToAccountMissing"
                , @"Transfer\_Prepare_ascx\.CreditGammingAccount_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\Transfer.ascx.resx"
                , "Field_Amount"
                , @"Transfer\_Prepare_ascx\.CurrencyAmount_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Transfer.ascx.resx"
                , "Validation_AmountMissing"
                , @"Transfer\_Prepare_ascx\.CurrencyAmount_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\Transfer.ascx.resx"
                , "Validation_IsufficientFunds"
                , @"Transfer\_Prepare_ascx\.CurrencyAmount_Insufficient"
                );
            CopyResource(@"opCommon\App_LocalResources\Transfer.ascx.resx"
                , "Validation_AmountLimits"
                , @"Transfer\_Prepare_ascx\.CurrencyAmount_OutsideRange"
                );
            CopyResource(@"opCommon\App_LocalResources\Transfer.ascx.resx"
                , "Tip_MinAmount"
                , @"Transfer\_Prepare_ascx\.Min"
                );
            /*
            CopyResource(@"opCommon\App_LocalResources\Transfer.ascx.resx"
                , "Tip_MaxAmount"
                , @"Transfer\_Prepare_ascx\.Max"
                );
             * */
            CopyResource(@"opCommon\App_LocalResources\Transfer.ascx.resx"
                , "Button_ConfirmGoBack"
                , @"Transfer\_Index_aspx\.Button_Back"
                );
            CopyResource(@"opCommon\App_LocalResources\Transfer.ascx.resx"
                , "Button_Confirm"
                , @"Transfer\_Index_aspx\.Button_Confirm"
                );
            CopyResource(@"opCommon\App_LocalResources\Transfer.ascx.resx"
                , "Button_Transfer"
                , @"Transfer\_Prepare_ascx\.Button_Transfer"
                );
            CopyResource(@"opCommon\App_LocalResources\Transfer.ascx.resx"
                , "Done_Message"
                , @"Transfer\_Receipt_ascx\.Success_Message"
                );
            CopyResource(@"opCommon\App_LocalResources\Transfer.ascx.resx"
                , "Error_Message"
                , @"Transfer\_Error_ascx\.Message"
                );
        }

        private static void CopyPendingWithdrawals()
        {
            CopyResource(@"opCommon\App_LocalResources\WithdrawRollback.ascx.resx"
                , "Anonymous_Message"
                , @"PendingWithdrawal\_Anonymous_aspx\.Message"
                );
            CopyResource(@"opCommon\App_LocalResources\WithdrawRollback.ascx.resx"
                , "No_Pending"
                , @"PendingWithdrawal\_NoPendingWithdrawal_aspx\.Message"
                );
            /*
            CopyResource(@"opCommon\App_LocalResources\WithdrawRollback.ascx.resx"
                , "Introduction"
                , @"PendingWithdrawal\_Index_aspx\.Message"
                );*/
            CopyResource(@"opCommon\App_LocalResources\WithdrawRollback.ascx.resx"
                , "Date"
                , @"PendingWithdrawal\_Index_aspx\.ListHeader_Date"
                );
            CopyResource(@"opCommon\App_LocalResources\WithdrawRollback.ascx.resx"
                , "From"
                , @"PendingWithdrawal\_Index_aspx\.ListHeader_DebitFrom"
                );
            CopyResource(@"opCommon\App_LocalResources\WithdrawRollback.ascx.resx"
                , "Amount"
                , @"PendingWithdrawal\_Index_aspx\.ListHeader_Amount"
                );
            CopyResource(@"opCommon\App_LocalResources\WithdrawRollback.ascx.resx"
                , "Error_Message"
                , @"PendingWithdrawal\_Error_aspx\.Message"
                );
            CopyResource(@"opCommon\App_LocalResources\WithdrawRollback.ascx.resx"
                , "Success_Message"
                , @"PendingWithdrawal\_Receipt_aspx\.Message"
                );
        }

        private static void CopyAccountStatement()
        {
            CopyResource(@"opCommon\App_LocalResources\TransactionList.ascx.resx"
                , "Header_Text"
                , @"AccountStatement\_Index_aspx\.HEAD_TEXT"
                );
            CopyResource(@"App_GlobalResources\Messages.resx"
                , "User_NotLoggedIn"
                , @"AccountStatement\_Anonymous_aspx\.Message"
                );
            CopyResource(@"opCommon\App_LocalResources\TransactionList.ascx.resx"
                , "All"
                , @"AccountStatement\_Index_aspx\.All"
                );
            CopyResource(@"opCommon\App_LocalResources\TransactionList.ascx.resx"
                , "Type_AffiliateFee"
                , @"AccountStatement\_Index_aspx\.Type_AffiliateFee"
                );
            CopyResource(@"opCommon\App_LocalResources\TransactionList.ascx.resx"
                , "Type_BuddyTransfer"
                , @"AccountStatement\_Index_aspx\.Type_BuddyTransfer"
                );
            CopyResource(@"opCommon\App_LocalResources\TransactionList.ascx.resx"
                , "Type_CasinoFPP"
                , @"AccountStatement\_Index_aspx\.Type_CasinoFPP"
                );
            CopyResource(@"opCommon\App_LocalResources\TransactionList.ascx.resx"
                , "Type_Deposit"
                , @"AccountStatement\_Index_aspx\.Type_Deposit"
                );
            CopyResource(@"opCommon\App_LocalResources\TransactionList.ascx.resx"
                , "Type_PokerCredit"
                , @"AccountStatement\_Index_aspx\.Type_PokerCredit"
                );
            CopyResource(@"opCommon\App_LocalResources\TransactionList.ascx.resx"
                , "Type_PokerDebit"
                , @"AccountStatement\_Index_aspx\.Type_PokerDebit"
                );
            CopyResource(@"opCommon\App_LocalResources\TransactionList.ascx.resx"
                , "Type_Transfer"
                , @"AccountStatement\_Index_aspx\.Type_Transfer"
                );
            CopyResource(@"opCommon\App_LocalResources\TransactionList.ascx.resx"
                , "Type_Withdraw"
                , @"AccountStatement\_Index_aspx\.Type_Withdraw"
                );

            CopyResource(@"App_GlobalResources\Funds.resx"
                , "Ref"
                , @"AccountStatement\_Index_aspx\.ListHeader_TransactionID"
                );
            CopyResource(@"App_GlobalResources\Funds.resx"
                , "Date"
                , @"AccountStatement\_Index_aspx\.ListHeader_Date"
                );
            CopyResource(@"App_GlobalResources\Funds.resx"
                , "Account"
                , @"AccountStatement\_Index_aspx\.ListHeader_Account"
                );
            CopyResource(@"App_GlobalResources\Funds.resx"
                , "Description"
                , @"AccountStatement\_Index_aspx\.ListHeader_Description"
                );
            CopyResource(@"App_GlobalResources\Funds.resx"
                , "Amount"
                , @"AccountStatement\_Index_aspx\.ListHeader_Amount"
                );
            CopyResource(@"App_GlobalResources\Funds.resx"
                , "Status"
                , @"AccountStatement\_Index_aspx\.ListHeader_Status"
                );
            CopyResource(@"App_GlobalResources\Funds.resx"
                , "FromAccount"
                , @"AccountStatement\_Index_aspx\.FromAccount"
                );
            CopyResource(@"App_GlobalResources\Funds.resx"
                , "ToAccount"
                , @"AccountStatement\_Index_aspx\.ToAccount"
                );
            CopyResource(@"App_GlobalResources\Funds.resx"
                , "TransferFromPlayer"
                , @"AccountStatement\_Index_aspx\.TransferFromPlayer"
                );
            CopyResource(@"App_GlobalResources\Funds.resx"
                , "TransferToPlayer"
                , @"AccountStatement\_Index_aspx\.TransferToPlayer"
                );

            CopyResource(@"App_GlobalResources\TransStatus.resx"
                , "Success"
                , @"AccountStatement\_Index_aspx\.Status_Success"
                );
            CopyResource(@"App_GlobalResources\TransStatus.resx"
                , "Setup"
                , @"AccountStatement\_Index_aspx\.Status_Setup"
                );
            CopyResource(@"App_GlobalResources\TransStatus.resx"
                , "Failed"
                , @"AccountStatement\_Index_aspx\.Status_Failed"
                );
            CopyResource(@"App_GlobalResources\TransStatus.resx"
                , "Processing"
                , @"AccountStatement\_Index_aspx\.Status_Processing"
                );
            CopyResource(@"App_GlobalResources\TransStatus.resx"
                , "Pending"
                , @"AccountStatement\_Index_aspx\.Status_Pending"
                );
            CopyResource(@"App_GlobalResources\TransStatus.resx"
                , "ProcessingDebit"
                , @"AccountStatement\_Index_aspx\.Status_ProcessingDebit"
                );
            
            CopyResource(@"App_GlobalResources\TransStatus.resx"
                , "Cancelled"
                , @"AccountStatement\_Index_aspx\.Status_Cancelled"
                );
            CopyResource(@"App_GlobalResources\TransStatus.resx"
                , "RollBack"
                , @"AccountStatement\_Index_aspx\.Status_RollBack"
                );
            /*
             * CopyResource(@"App_GlobalResources\TransStatus.resx"
                , "DebitFailed"
                , @"AccountStatement\_Index_aspx\.Status_DebitFailed"
                );
            CopyResource(@"App_GlobalResources\TransStatus.resx"
                , "CreditFailed"
                , @"AccountStatement\_Index_aspx\.Status_CreditFailed"
                );
            CopyResource(@"App_GlobalResources\TransStatus.resx"
                , "PendingNotification"
                , @"AccountStatement\_Index_aspx\.Status_PendingNotification"
                );
             * */

            CopyResource(@"opCommon\App_LocalResources\WithdrawRollback.ascx.resx"
                , "Rollback"
                , @"AccountStatement\_Withdraw_ascx\.Button_Rollback"
                );
        }

        private static void CopyWithdraw()
        {
            CopyResource(@"opCommon\App_LocalResources\Withdraw.ascx.resx"
                , "Header_Withdrawal"
                , @"Withdraw\_Index_aspx\.HEAD_TEXT"
                );
            CopyResource(@"opCommon\App_LocalResources\Withdraw.ascx.resx"
                , "Anonymous_Message"
                , @"Withdraw\_Anonymous_aspx\.Message"
                );
            CopyResource(@"opCommon\App_LocalResources\Withdraw.ascx.resx"
                , "Error_UserInactive"
                , @"Withdraw\_EmailNotVerified_aspx\.Message"
                );
            CopyResource(@"opCommon\App_LocalResources\Withdraw.ascx.resx"
                , "Header_Note"
                , @"Withdraw\_Index_aspx\.Withdrawal_Options"
                );
            CopyResource(@"opCommon\App_LocalResources\Withdraw.ascx.resx"
                , "ListHeader_Type"
                , @"Withdraw\_Index_aspx\.ListHeader_Type"
                );
            CopyResource(@"opCommon\App_LocalResources\Withdraw.ascx.resx"
                , "ListHeader_Fee"
                , @"Withdraw\_Index_aspx\.ListHeader_Fee"
                );
            CopyResource(@"opCommon\App_LocalResources\Withdraw.ascx.resx"
                , "ListHeader_Limits"
                , @"Withdraw\_Index_aspx\.ListHeader_Limits"
                );

            CopyResource(@"opCommon\App_LocalResources\Withdraw.ascx.resx"
                , "Field_Account"
                , @"Withdraw\_InputView_ascx\.GammingAccount_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Withdraw.ascx.resx"
                , "Validation_AccountMissing"
                , @"Withdraw\_InputView_ascx\.GammingAccount_Empty"
                );
            
            CopyResource(@"opCommon\App_LocalResources\Withdraw.ascx.resx"
                , "Field_Amount"
                , @"Withdraw\_InputView_ascx\.CurrencyAmount_Label"
                );

            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Validation_AmountMissing"
                , @"Withdraw\_InputView_ascx\.CurrencyAmount_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Validation_AmountOutsideRange"
                , @"Withdraw\_InputView_ascx\.CurrencyAmount_OutsideRange"
                );
            CopyResource(@"opCommon\App_LocalResources\Withdraw.ascx.resx"
                , "Validation_InsufficientFunds"
                , @"Withdraw\_InputView_ascx\.CurrencyAmount_Insufficient"
                );

            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Tip_MaxAmount"
                , @"Withdraw\_InputView_ascx\.Max"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Tip_MinAmount"
                , @"Withdraw\_InputView_ascx\.Min"
                );

            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Button_ConfirmGoBack"
                , @"Withdraw\_Prepare_aspx\.Button_Back"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Button_Continue"
                , @"Withdraw\_Prepare_aspx\.Button_Continue"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Button_Confirm"
                , @"Withdraw\_Prepare_aspx\.Button_Confirm"
                );

            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Stardard.ascx.resx"
                , "WithdrawTo"
                , @"Withdraw\_Prepare_aspx\.WithdrawTo"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\WithdrawConfirmation.ascx.resx"
                , "Confirm_Total"
                , @"Withdraw\_Confirmation_ascx\.DebitAccount"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\WithdrawConfirmation.ascx.resx"
                , "ConfirmFee"
                , @"Withdraw\_Confirmation_ascx\.Fee"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\WithdrawConfirmation.ascx.resx"
                , "ConfirmFee"
                , @"Withdraw\_Receipt_aspx\.Fee"
                );
            CopyResource(@"opCommon\App_LocalResources\Withdraw.ascx.resx"
                , "Done_Message"
                , @"Withdraw\_Receipt_aspx\.Pending_Message"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\WithdrawConfirmation.ascx.resx"
                , "Confirm_Total"
                , @"Withdraw\_Receipt_aspx\.DebitAccount"
                );
            /*
            CopyResource(@"opCommon\Payment\App_LocalResources\WithdrawConfirmation.ascx.resx"
                , "Confirm_TransferToUser"
                , @"Withdraw\_Confirmation_ascx\.Credit_Amount"
                );
             * */

            // Bank
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Select_Account"
                , @"Withdraw\_BankPayCard_ascx\.Tab_RecentPayCards"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Register_Account"
                , @"Withdraw\_BankPayCard_ascx\.Tabs_RegisterPayCard"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Country"
                , @"Withdraw\_BankPayCard_ascx\.BankCountry_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Bank_Name"
                , @"Withdraw\_BankPayCard_ascx\.BankName_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Bank_Name_Empty"
                , @"Withdraw\_BankPayCard_ascx\.BankName_Empty"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Bank_Code"
                , @"Withdraw\_BankPayCard_ascx\.BankCode_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Bank_Code_Empty"
                , @"Withdraw\_BankPayCard_ascx\.BankCode_Empty"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Account_Holding_Branch"
                , @"Withdraw\_BankPayCard_ascx\.BranchAddress_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Bank_Address_Empty"
                , @"Withdraw\_BankPayCard_ascx\.BranchAddress_Empty"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Branch_Code"
                , @"Withdraw\_BankPayCard_ascx\.BranchCode_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Branch_Code_Empty"
                , @"Withdraw\_BankPayCard_ascx\.BranchCode_Empty"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Payee"
                , @"Withdraw\_BankPayCard_ascx\.Payee_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Payee_Empty"
                , @"Withdraw\_BankPayCard_ascx\.Payee_Empty"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Account_Number"
                , @"Withdraw\_BankPayCard_ascx\.AccountNumber_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Account_Number_Empty"
                , @"Withdraw\_BankPayCard_ascx\.AccountNumber_Empty"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "IBAN"
                , @"Withdraw\_BankPayCard_ascx\.IBAN_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "IBAN_Empty"
                , @"Withdraw\_BankPayCard_ascx\.IBAN_Empty"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "SWIFT"
                , @"Withdraw\_BankPayCard_ascx\.SWIFT_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "SWIFT_Empty"
                , @"Withdraw\_BankPayCard_ascx\.SWIFT_Empty"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Check_Digits"
                , @"Withdraw\_BankPayCard_ascx\.CheckDigits_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Check_Digits_Empty"
                , @"Withdraw\_BankPayCard_ascx\.CheckDigits_Empty"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Personal_ID_Number"
                , @"Withdraw\_BankPayCard_ascx\.PersonalIDNumber_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Withdraw_Envoy.ascx.resx"
                , "Additional_Information_Empty"
                , @"Withdraw\_BankPayCard_ascx\.PersonalIDNumber_Empty"
                );

        }

        private static void CopyDeposit()
        {
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "FilterHeader"
                , @"Deposit\_PaymentMethodFilterView_ascx\.Legend_Filter"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "ChooseCountry"
                , @"Deposit\_PaymentMethodFilterView_ascx\.Choose_Country"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "ChooseCurrency"
                , @"Deposit\_PaymentMethodFilterView_ascx\.Choose_Currency"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Filter"
                , @"Deposit\_PaymentMethodFilterView_ascx\.Button_Filter"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Fee"
                , @"Deposit\_PaymentMethodList_ascx\.Fee"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Processing"
                , @"Deposit\_PaymentMethodList_ascx\.Processing"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "TransactionLimit"
                , @"Deposit\_PaymentMethodList_ascx\.Transaction_Limit"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Deposit"
                , @"Deposit\_PaymentMethodList_ascx\.Deposit"
                ); 
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Deposit_SupportWithdraw"
                , @"Deposit\_PaymentMethodList_ascx\.Bank_Withdraw_Only"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "ProcessingTime_Immediately"
                , @"Metadata\ProcessTime\.Immediately"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "ProcessingTime_Instant"
                , @"Metadata\ProcessTime\.Instant"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "ProcessingTime_ThreeToFiveDays"
                , @"Metadata\ProcessTime\.ThreeToFiveDays"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "ProcessingTime_Variable"
                , @"Metadata\ProcessTime\.Variable"
                );
            
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Button_ConfirmGoBack"
                , @"Deposit\_BonusTC_ascx\.Button_Back"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Accept"
                , @"Deposit\_BonusTC_ascx\.Button_Accept"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Reject"
                , @"Deposit\_BonusTC_ascx\.Button_Reject"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Remember_For_1_Week"
                , @"Deposit\_BonusTC_ascx\.Remember_For_1_Week"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Remember_For_1_Month"
                , @"Deposit\_BonusTC_ascx\.Remember_For_1_Month"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Do_Not_Remember"
                , @"Deposit\_BonusTC_ascx\.Do_Not_Remember"
                );

            CopyResource(@"opCommon\Payment\App_LocalResources\DepositConfirmation.ascx.resx"
                , "ConfirmVendorAccount"
                , @"Deposit\_Confirmation_ascx\.From_Account"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\DepositConfirmation.ascx.resx"
                , "ConfirmCredit"
                , @"Deposit\_Confirmation_ascx\.Credit_Account"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\DepositConfirmation_PaymentTrust.ascx.resx"
                , "ConfirmDebit"
                , @"Deposit\_Confirmation_ascx\.Debit_Card"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\DepositConfirmation.ascx.resx"
                , "ConfirmDebit"
                , @"Deposit\_Confirmation_ascx\.Debit_Account"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\DepositConfirmation.ascx.resx"
                , "Fee"
                , @"Deposit\_Confirmation_ascx\.Fee"
                );
            /*
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "ConfirmButton_Notes"
                , @"Deposit\_Confirmation_ascx\.Confirmation_Notes"
                );
             *  * */

            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Anonymous_Message"
                , @"Deposit\_Anonymous_aspx\.Message"
                );
            /*
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Error_UserInactive"
                , @"Deposit\_EmailNotVerified_aspx\.Message"
                );
             * */
            // PT
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Validation_PayCardMissing"
                , @"Deposit\_PaymentTrustPayCard_ascx\.ExistingCard_Empty"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\PaymentTrust_Reg.ascx.resx"
                , "CardNumber"
                , @"Deposit\_PaymentTrustPayCard_ascx\.CardNumber_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\PaymentTrust_Reg.ascx.resx"
                , "CardNumerEmpty"
                , @"Deposit\_PaymentTrustPayCard_ascx\.CardNumber_Empty"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\PaymentTrust_Reg.ascx.resx"
                , "CardNumberInvalid"
                , @"Deposit\_PaymentTrustPayCard_ascx\.CardNumber_Invalid"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\PaymentTrust_Reg.ascx.resx"
                , "CardholderName"
                , @"Deposit\_PaymentTrustPayCard_ascx\.CardHolderName_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\PaymentTrust_Reg.ascx.resx"
                , "CardholderNameEmpty"
                , @"Deposit\_PaymentTrustPayCard_ascx\.CardHolderName_Empty"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\PaymentTrust_Reg.ascx.resx"
                , "CardIssueNumber"
                , @"Deposit\_PaymentTrustPayCard_ascx\.CardIssueNumber_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\PaymentTrust_Reg.ascx.resx"
                , "CardholderNameEmpty"
                , @"Deposit\_PaymentTrustPayCard_ascx\.CardIssueNumber_Empty"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\PaymentTrust_Reg.ascx.resx"
                , "CardSecurityCode"
                , @"Deposit\_PaymentTrustPayCard_ascx\.CardSecurityCode_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\PaymentTrust_Reg.ascx.resx"
                , "CardSecurityCodeEpmty"
                , @"Deposit\_PaymentTrustPayCard_ascx\.CardSecurityCode_Empty"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\PaymentTrust_Reg.ascx.resx"
                , "CardSecurityCodeInvalid"
                , @"Deposit\_PaymentTrustPayCard_ascx\.CardSecurityCode_Invalid"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\PaymentTrust_Reg.ascx.resx"
                , "ExpiryDate"
                , @"Deposit\_PaymentTrustPayCard_ascx\.CardExpiryDate_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\PaymentTrust_Reg.ascx.resx"
                , "ExpiryDateEmpty"
                , @"Deposit\_PaymentTrustPayCard_ascx\.CardExpiryDate_Empty"
                );

            CopyResource(@"opCommon\Payment\App_LocalResources\PaymentTrust_Reg.ascx.resx"
                , "Month"
                , @"Deposit\_PaymentTrustPayCard_ascx\.Month"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\PaymentTrust_Reg.ascx.resx"
                , "Year"
                , @"Deposit\_PaymentTrustPayCard_ascx\.Year"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\PaymentTrust_Reg.ascx.resx"
                , "ValidFrom"
                , @"Deposit\_PaymentTrustPayCard_ascx\.ValidFrom_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\PaymentTrust_Reg.ascx.resx"
                , "ValidFromEmpty"
                , @"Deposit\_PaymentTrustPayCard_ascx\.ValidFrom_Empty"
                );


            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "PostingMessage"
                , @"Deposit\_PaymentFormPost_aspx\.Message"
                ); 
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Deposit"
                , @"Deposit\_Index_aspx\.HEAD_TEXT"
                ); 
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Button_ConfirmGoBack"
                , @"Deposit\_Index_aspx\.Button_Back"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Button_Continue"
                , @"Deposit\_Index_aspx\.Button_Continue"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Button_Confirm"
                , @"Deposit\_Index_aspx\.Button_Confirm"
                ); 
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Button_ConfirmGoBack"
                , @"Deposit\_PaymentTrustPayCard_ascx\.Button_Back"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Tabs_RecentPayCards"
                , @"Deposit\_Index_aspx\.Tab_RecentPayCards"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Tabs_RegisterPayCard"
                , @"Deposit\_Index_aspx\.Tabs_RegisterPayCard"
                );

            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "SelectAccountAndAmount"
                , @"Deposit\_PrepareEnvoy_aspx\.GammingAccount_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Validation_SelectDepositAccount"
                , @"Deposit\_PrepareEnvoy_aspx\.GammingAccount_Empty"
                );

            
            
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "SelectAccountAndAmount"
                , @"Deposit\_InputView_ascx\.GammingAccount_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Validation_SelectDepositAccount"
                , @"Deposit\_InputView_ascx\.GammingAccount_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Field_DepositAmount"
                , @"Deposit\_InputView_ascx\.CurrencyAmount_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Validation_AmountMissing"
                , @"Deposit\_InputView_ascx\.CurrencyAmount_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Validation_AmountOutsideRange"
                , @"Deposit\_InputView_ascx\.CurrencyAmount_OutsideRange"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Validation_AmountNoBonus"
                , @"Deposit\_InputView_ascx\.CurrencyAmount_NoBonus"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Tip_MaxAmount"
                , @"Deposit\_InputView_ascx\.Max"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Tip_MinAmount"
                , @"Deposit\_InputView_ascx\.Min"
                ); 

            // receipt
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Receipt_Success"
                , @"Deposit\_Receipt_aspx\.Success_Message"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Receipt_DateTime"
                , @"Deposit\_Receipt_aspx\.Date_Time"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Receipt_Credit"
                , @"Deposit\_Receipt_aspx\.Receipt_Credit"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Receipt_Fee"
                , @"Deposit\_Receipt_aspx\.Receipt_Fee"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Receipt_Debit_EWallet"
                , @"Deposit\_Receipt_aspx\.Receipt_Debit"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\DepositConfirmation_PaymentTrust.ascx.resx"
                , "ConfirmDebit"
                , @"Deposit\_Receipt_aspx\.Debit_Card"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Receipt_TransRef"
                , @"Deposit\_Receipt_aspx\.Transaction_ID"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Receipt_Support"
                , @"Deposit\_Receipt_aspx\.Information_Message"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Receipt"
                , @"Deposit\_Receipt_aspx\.HEAD_TEXT"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Button_Print"
                , @"Deposit\_Receipt_aspx\.Button_Print"
                );

            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Cancel_Message"
                , @"Deposit\_Cancel_aspx\.Message"
                );

            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Error_GeneralMessage"
                , @"Deposit\_Error_aspx\.Message"
                );

            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Pending_Message"
                , @"Deposit\_EnvoySuccess_aspx\.Message"
                );

            // MB
            CopyResource(@"opCommon\Payment\App_LocalResources\Moneybookers_Reg.ascx.resx"
                , "Field_Email"
                , @"Deposit\_MoneybookersPayCard_ascx\.Email_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Moneybookers_Reg.ascx.resx"
                , "Validation_EmailEmpty"
                , @"Deposit\_MoneybookersPayCard_ascx\.Email_Empty"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Moneybookers_Reg.ascx.resx"
                , "Validation_EmailError"
                , @"Deposit\_MoneybookersPayCard_ascx\.Email_Invalid"
                );

            // Voucher
            CopyResource(@"opCommon\Payment\App_LocalResources\Voucher_Reg.ascx.resx"
                , "CardNumber"
                , @"Deposit\_VoucherPayCard_ascx\.VoucherCardNumber_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Voucher_Reg.ascx.resx"
                , "CardNumber_Empty"
                , @"Deposit\_VoucherPayCard_ascx\.VoucherCardNumber_Empty"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Voucher_Reg.ascx.resx"
                , "CardNumber_Error"
                , @"Deposit\_VoucherPayCard_ascx\.VoucherCardNumber_Invalid"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Voucher_Reg.ascx.resx"
                , "SecretKey"
                , @"Deposit\_VoucherPayCard_ascx\.ValidationCode_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Voucher_Reg.ascx.resx"
                , "SecretKey"
                , @"Deposit\_VoucherPayCard_ascx\.ValidationCode_Label"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Voucher_Reg.ascx.resx"
                , "SecretKey_Empty"
                , @"Deposit\_VoucherPayCard_ascx\.ValidationCode_Empty"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\Voucher_Reg.ascx.resx"
                , "SecretKey_Error"
                , @"Deposit\_VoucherPayCard_ascx\.ValidationCode_Invalid"
                );

            // EntroPay
            CopyResource(@"opCommon\Payment\App_LocalResources\EntroPay.aspx.resx"
                , "SubTitle"
                , @"Deposit\_EntroPay_aspx\.Title"
                );
            /*
            CopyResource(@"opCommon\Payment\App_LocalResources\EntroPay.aspx.resx"
                , "Intro"
                , @"Deposit\_EntroPay_aspx\.Intro"
                );
             * */
            CopyResource(@"opCommon\Payment\App_LocalResources\EntroPay.aspx.resx"
                , "HowItWorks"
                , @"Deposit\_EntroPay_aspx\.How_It_Works"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\EntroPay.aspx.resx"
                , "Step1"
                , @"Deposit\_EntroPay_aspx\.Step1"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\EntroPay.aspx.resx"
                , "Step2"
                , @"Deposit\_EntroPay_aspx\.Step2"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\EntroPay.aspx.resx"
                , "Step3"
                , @"Deposit\_EntroPay_aspx\.Step3"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\EntroPay.aspx.resx"
                , "SafeWay"
                , @"Deposit\_EntroPay_aspx\.Safe_Way"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\EntroPay.aspx.resx"
                , "AlreadyUser"
                , @"Deposit\_EntroPay_aspx\.Already_EntroPay_User"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\EntroPay.aspx.resx"
                , "ClickHere"
                , @"Deposit\_EntroPay_aspx\.Click_Here"
                );
            CopyResource(@"opCommon\Payment\App_LocalResources\EntroPay.aspx.resx"
                , "Register"
                , @"Deposit\_EntroPay_aspx\.Register_EntroPay"
                );
        }

        private static void CopyPaymentMethods()
        {
            /*
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "CreditCards"
                , @"Metadata\PaymentMethodCategory\CreditCard\.Display_Name"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "DebitCards"
                , @"Metadata\PaymentMethodCategory\DebitCard\.Display_Name"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "BankTransfer"
                , @"Metadata\PaymentMethodCategory\BankTransfer\.Display_Name"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "DirectEbanking"
                , @"Metadata\PaymentMethodCategory\DirectEbanking\.Display_Name"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "Ewallets"
                , @"Metadata\PaymentMethodCategory\Ewallet\.Display_Name"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "FastBankTransfer"
                , @"Metadata\PaymentMethodCategory\FastBankTransfer\.Display_Name"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "InstantBanking"
                , @"Metadata\PaymentMethodCategory\InstantBanking\.Display_Name"
                );
            CopyResource(@"opCommon\App_LocalResources\Deposit.ascx.resx"
                , "PrePaidCards"
                , @"Metadata\PaymentMethodCategory\PrePaidCard\.Display_Name"
                );

            // VISA
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "paymenttrust_vi"
                , @"Metadata\PaymentMethod\VISA\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "paymenttrust_vi"
                , @"Metadata\PaymentMethod\VISA\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "paymenttrust_vi"
                , @"Metadata\PaymentMethod\VISA\.Withdraw_Message"
                );

            // VISA_Electron
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "paymenttrust_ve"
                , @"Metadata\PaymentMethod\VISA_Electron\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "paymenttrust_ve"
                , @"Metadata\PaymentMethod\VISA_Electron\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "paymenttrust_ve"
                , @"Metadata\PaymentMethod\VISA_Electron\.Withdraw_Message"
                );

            // VISA_Debit
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "paymenttrust_vd"
                , @"Metadata\PaymentMethod\VISA_Debit\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "paymenttrust_vd"
                , @"Metadata\PaymentMethod\VISA_Debit\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "paymenttrust_vd"
                , @"Metadata\PaymentMethod\VISA_Debit\.Withdraw_Message"
                );

            // MasterCard
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "paymenttrust_mc"
                , @"Metadata\PaymentMethod\MasterCard\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "paymenttrust_mc"
                , @"Metadata\PaymentMethod\MasterCard\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "paymenttrust_mc"
                , @"Metadata\PaymentMethod\MasterCard\.Withdraw_Message"
                );

            // Switch
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "paymenttrust_sw"
                , @"Metadata\PaymentMethod\Switch\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "paymenttrust_sw"
                , @"Metadata\PaymentMethod\Switch\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "paymenttrust_sw"
                , @"Metadata\PaymentMethod\Switch\.Withdraw_Message"
                );

            // Solo
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "paymenttrust_sw"
                , @"Metadata\PaymentMethod\Solo\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "paymenttrust_sw"
                , @"Metadata\PaymentMethod\Solo\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "paymenttrust_sw"
                , @"Metadata\PaymentMethod\Solo\.Withdraw_Message"
                );

            // Maestro
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "paymenttrust_mamd"
                , @"Metadata\PaymentMethod\Maestro\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "paymenttrust_mamd"
                , @"Metadata\PaymentMethod\Maestro\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "paymenttrust_mamd"
                , @"Metadata\PaymentMethod\Maestro\.Withdraw_Message"
                );

            // EntroPay
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "paymenttrust_entropay"
                , @"Metadata\PaymentMethod\EntroPay\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "paymenttrust_entropay"
                , @"Metadata\PaymentMethod\EntroPay\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "paymenttrust_entropay"
                , @"Metadata\PaymentMethod\EntroPay\.Withdraw_Message"
                );

            // Neteller
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "neteller"
                , @"Metadata\PaymentMethod\Neteller\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "neteller"
                , @"Metadata\PaymentMethod\Neteller\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "neteller"
                , @"Metadata\PaymentMethod\Neteller\.Withdraw_Message"
                );

            // Neteller_1Pay
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "neteller_1pay"
                , @"Metadata\PaymentMethod\Neteller_1Pay\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "neteller_1pay"
                , @"Metadata\PaymentMethod\Neteller_1Pay\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "neteller_1pay"
                , @"Metadata\PaymentMethod\Neteller_1Pay\.Withdraw_Message"
                );

            // Voucher
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "voucher"
                , @"Metadata\PaymentMethod\Voucher\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "voucher"
                , @"Metadata\PaymentMethod\Voucher\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "voucher"
                , @"Metadata\PaymentMethod\Voucher\.Withdraw_Message"
                );

            // QVoucher
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "qvoucher"
                , @"Metadata\PaymentMethod\QVoucher\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "qvoucher"
                , @"Metadata\PaymentMethod\QVoucher\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "qvoucher"
                , @"Metadata\PaymentMethod\QVoucher\.Withdraw_Message"
                );

            // ClickandBuy
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "clickandbuy"
                , @"Metadata\PaymentMethod\ClickandBuy\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "clickandbuy"
                , @"Metadata\PaymentMethod\ClickandBuy\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "clickandbuy"
                , @"Metadata\PaymentMethod\ClickandBuy\.Withdraw_Message"
                );

            // Click2Pay
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "click2pay"
                , @"Metadata\PaymentMethod\Click2Pay\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "click2pay"
                , @"Metadata\PaymentMethod\Click2Pay\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "click2pay"
                , @"Metadata\PaymentMethod\Click2Pay\.Withdraw_Message"
                );

            // Ukash
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "ukash"
                , @"Metadata\PaymentMethod\Ukash\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "ukash"
                , @"Metadata\PaymentMethod\Ukash\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "ukash"
                , @"Metadata\PaymentMethod\Ukash\.Withdraw_Message"
                );

            // Paysafecard
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "paysafecard"
                , @"Metadata\PaymentMethod\Paysafecard\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "paysafecard"
                , @"Metadata\PaymentMethod\Paysafecard\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "paysafecard"
                , @"Metadata\PaymentMethod\Paysafecard\.Withdraw_Message"
                );

            // BankTransfer
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "banktransfer"
                , @"Metadata\PaymentMethod\BankTransfer\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "banktransfer"
                , @"Metadata\PaymentMethod\BankTransfer\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "banktransfer"
                , @"Metadata\PaymentMethod\BankTransfer\.Withdraw_Message"
                );

            // Moneybookers
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers"
                , @"Metadata\PaymentMethod\Moneybookers\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers"
                , @"Metadata\PaymentMethod\Moneybookers\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers"
                , @"Metadata\PaymentMethod\Moneybookers\.Withdraw_Message"
                );

            // Moneybookers_CreditCard
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_allcreditcard"
                , @"Metadata\PaymentMethod\Moneybookers_CreditCard\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_allcreditcard"
                , @"Metadata\PaymentMethod\Moneybookers_CreditCard\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_allcreditcard"
                , @"Metadata\PaymentMethod\Moneybookers_CreditCard\.Withdraw_Message"
                );

            // Moneybookers_VISA
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_visa"
                , @"Metadata\PaymentMethod\Moneybookers_VISA\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_visa"
                , @"Metadata\PaymentMethod\Moneybookers_VISA\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_visa"
                , @"Metadata\PaymentMethod\Moneybookers_VISA\.Withdraw_Message"
                );

            // Moneybookers_MasterCard
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_mastercard"
                , @"Metadata\PaymentMethod\Moneybookers_MasterCard\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_mastercard"
                , @"Metadata\PaymentMethod\Moneybookers_MasterCard\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_mastercard"
                , @"Metadata\PaymentMethod\Moneybookers_MasterCard\.Withdraw_Message"
                );

            // Moneybookers_VISA_Debit
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_visadeltadebit"
                , @"Metadata\PaymentMethod\Moneybookers_VISA_Debit\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_visadeltadebit"
                , @"Metadata\PaymentMethod\Moneybookers_VISA_Debit\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_visadeltadebit"
                , @"Metadata\PaymentMethod\Moneybookers_VISA_Debit\.Withdraw_Message"
                );

            // Moneybookers_VISA_Electron
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_visaelectron"
                , @"Metadata\PaymentMethod\Moneybookers_VISA_Electron\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_visaelectron"
                , @"Metadata\PaymentMethod\Moneybookers_VISA_Electron\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_visaelectron"
                , @"Metadata\PaymentMethod\Moneybookers_VISA_Electron\.Withdraw_Message"
                );

            // Moneybookers_Diners
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_diners"
                , @"Metadata\PaymentMethod\Moneybookers_Diners\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_diners"
                , @"Metadata\PaymentMethod\Moneybookers_Diners\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_diners"
                , @"Metadata\PaymentMethod\Moneybookers_Diners\.Withdraw_Message"
                );

            // Moneybookers_Maestro
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_maestro"
                , @"Metadata\PaymentMethod\Moneybookers_Maestro\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_maestro"
                , @"Metadata\PaymentMethod\Moneybookers_Maestro\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_maestro"
                , @"Metadata\PaymentMethod\Moneybookers_Maestro\.Withdraw_Message"
                );

            // Moneybookers_Solo
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_solo"
                , @"Metadata\PaymentMethod\Moneybookers_Solo\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_solo"
                , @"Metadata\PaymentMethod\Moneybookers_Solo\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_solo"
                , @"Metadata\PaymentMethod\Moneybookers_Solo\.Withdraw_Message"
                );

            // Moneybookers_Laser
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_laser"
                , @"Metadata\PaymentMethod\Moneybookers_Laser\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_laser"
                , @"Metadata\PaymentMethod\Moneybookers_Laser\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_laser"
                , @"Metadata\PaymentMethod\Moneybookers_Laser\.Withdraw_Message"
                );

            // Moneybookers_CartaSi
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_cartasi"
                , @"Metadata\PaymentMethod\Moneybookers_CartaSi\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_cartasi"
                , @"Metadata\PaymentMethod\Moneybookers_CartaSi\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_cartasi"
                , @"Metadata\PaymentMethod\Moneybookers_CartaSi\.Withdraw_Message"
                );

            // Moneybookers_PostePay
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_postepay"
                , @"Metadata\PaymentMethod\Moneybookers_PostePay\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_postepay"
                , @"Metadata\PaymentMethod\Moneybookers_PostePay\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_postepay"
                , @"Metadata\PaymentMethod\Moneybookers_PostePay\.Withdraw_Message"
                );

            // Moneybookers_4B
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_fourb"
                , @"Metadata\PaymentMethod\Moneybookers_4B\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_fourb"
                , @"Metadata\PaymentMethod\Moneybookers_4B\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_fourb"
                , @"Metadata\PaymentMethod\Moneybookers_4B\.Withdraw_Message"
                );

            // Moneybookers_Euro6000
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_euro600"
                , @"Metadata\PaymentMethod\Moneybookers_Euro6000\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_euro600"
                , @"Metadata\PaymentMethod\Moneybookers_Euro6000\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_euro600"
                , @"Metadata\PaymentMethod\Moneybookers_Euro6000\.Withdraw_Message"
                );

            // Moneybookers_Dankort
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_dankort"
                , @"Metadata\PaymentMethod\Moneybookers_Dankort\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_dankort"
                , @"Metadata\PaymentMethod\Moneybookers_Dankort\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_dankort"
                , @"Metadata\PaymentMethod\Moneybookers_Dankort\.Withdraw_Message"
                );

            // Moneybookers_GiroPay
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_giropay"
                , @"Metadata\PaymentMethod\Moneybookers_GiroPay\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_giropay"
                , @"Metadata\PaymentMethod\Moneybookers_GiroPay\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_giropay"
                , @"Metadata\PaymentMethod\Moneybookers_GiroPay\.Withdraw_Message"
                );

            // Moneybookers_ELV
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_elv"
                , @"Metadata\PaymentMethod\Moneybookers_ELV\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_elv"
                , @"Metadata\PaymentMethod\Moneybookers_ELV\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_elv"
                , @"Metadata\PaymentMethod\Moneybookers_ELV\.Withdraw_Message"
                );

            // Moneybookers_Sofort
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_sofort"
                , @"Metadata\PaymentMethod\Moneybookers_Sofort\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_sofort"
                , @"Metadata\PaymentMethod\Moneybookers_Sofort\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_sofort"
                , @"Metadata\PaymentMethod\Moneybookers_Sofort\.Withdraw_Message"
                );

            // Moneybookers_Nordea
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_nordeafi"
                , @"Metadata\PaymentMethod\Moneybookers_Nordea\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_nordeafi"
                , @"Metadata\PaymentMethod\Moneybookers_Nordea\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_nordeafi"
                , @"Metadata\PaymentMethod\Moneybookers_Nordea\.Withdraw_Message"
                );

            // Moneybookers_Bank
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_bank"
                , @"Metadata\PaymentMethod\Moneybookers_Bank\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_bank"
                , @"Metadata\PaymentMethod\Moneybookers_Bank\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_bank"
                , @"Metadata\PaymentMethod\Moneybookers_Bank\.Withdraw_Message"
                );

            // Moneybookers_IDeal
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_ideal"
                , @"Metadata\PaymentMethod\Moneybookers_IDeal\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_ideal"
                , @"Metadata\PaymentMethod\Moneybookers_IDeal\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_ideal"
                , @"Metadata\PaymentMethod\Moneybookers_IDeal\.Withdraw_Message"
                );

            // Moneybookers_ePayBg
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_epaybg"
                , @"Metadata\PaymentMethod\Moneybookers_ePayBg\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_epaybg"
                , @"Metadata\PaymentMethod\Moneybookers_ePayBg\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_epaybg"
                , @"Metadata\PaymentMethod\Moneybookers_ePayBg\.Withdraw_Message"
                );

            // Moneybookers_ENets
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_enets"
                , @"Metadata\PaymentMethod\Moneybookers_ENets\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_enets"
                , @"Metadata\PaymentMethod\Moneybookers_ENets\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_enets"
                , @"Metadata\PaymentMethod\Moneybookers_ENets\.Withdraw_Message"
                );

            // Moneybookers_Poli
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_poli"
                , @"Metadata\PaymentMethod\Moneybookers_Poli\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_poli"
                , @"Metadata\PaymentMethod\Moneybookers_Poli\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_poli"
                , @"Metadata\PaymentMethod\Moneybookers_Poli\.Withdraw_Message"
                );
            // Moneybookers_Przelewy24
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "moneybookers_przelewy24"
                , @"Metadata\PaymentMethod\Moneybookers_Przelewy24\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "moneybookers_przelewy24"
                , @"Metadata\PaymentMethod\Moneybookers_Przelewy24\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "moneybookers_przelewy24"
                , @"Metadata\PaymentMethod\Moneybookers_Przelewy24\.Withdraw_Message"
                );

            // Envoy
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_banktransfer"
                , @"Metadata\PaymentMethod\Envoy\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_banktransfer"
                , @"Metadata\PaymentMethod\Envoy\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_banktransfer"
                , @"Metadata\PaymentMethod\Envoy\.Withdraw_Message"
                );

            // Envoy_BOLETO
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_boleto"
                , @"Metadata\PaymentMethod\Envoy_BOLETO\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_boleto"
                , @"Metadata\PaymentMethod\Envoy_BOLETO\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_boleto"
                , @"Metadata\PaymentMethod\Envoy_BOLETO\.Withdraw_Message"
                );

            // Envoy_IDeal
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_ideal"
                , @"Metadata\PaymentMethod\Envoy_IDeal\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_ideal"
                , @"Metadata\PaymentMethod\Envoy_IDeal\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_ideal"
                , @"Metadata\PaymentMethod\Envoy_IDeal\.Withdraw_Message"
                );

            // Envoy_Przelewy24
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_przelewy"
                , @"Metadata\PaymentMethod\Envoy_Przelewy24\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_przelewy"
                , @"Metadata\PaymentMethod\Envoy_Przelewy24\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_przelewy"
                , @"Metadata\PaymentMethod\Envoy_Przelewy24\.Withdraw_Message"
                );

            // Envoy_Poli
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_poli"
                , @"Metadata\PaymentMethod\Envoy_Poli\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_poli"
                , @"Metadata\PaymentMethod\Envoy_Poli\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_poli"
                , @"Metadata\PaymentMethod\Envoy_Poli\.Withdraw_Message"
                );

            // Envoy_ABAQOOS
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_abaqoos"
                , @"Metadata\PaymentMethod\Envoy_ABAQOOS\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_abaqoos"
                , @"Metadata\PaymentMethod\Envoy_ABAQOOS\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_abaqoos"
                , @"Metadata\PaymentMethod\Envoy_ABAQOOS\.Withdraw_Message"
                );

            // Envoy_UNet
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_banklink"
                , @"Metadata\PaymentMethod\Envoy_UNet\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_banklink"
                , @"Metadata\PaymentMethod\Envoy_UNet\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_banklink"
                , @"Metadata\PaymentMethod\Envoy_UNet\.Withdraw_Message"
                );

            // Envoy_Swedbank
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_banklinkswed"
                , @"Metadata\PaymentMethod\Envoy_Swedbank\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_banklinkswed"
                , @"Metadata\PaymentMethod\Envoy_Swedbank\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_banklinkswed"
                , @"Metadata\PaymentMethod\Envoy_Swedbank\.Withdraw_Message"
                );

            // Envoy_Sofort
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_sofort"
                , @"Metadata\PaymentMethod\Envoy_Sofort\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_sofort"
                , @"Metadata\PaymentMethod\Envoy_Sofort\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_sofort"
                , @"Metadata\PaymentMethod\Envoy_Sofort\.Withdraw_Message"
                );

            // Envoy_Moneta
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_moneta"
                , @"Metadata\PaymentMethod\Envoy_Moneta\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_moneta"
                , @"Metadata\PaymentMethod\Envoy_Moneta\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_moneta"
                , @"Metadata\PaymentMethod\Envoy_Moneta\.Withdraw_Message"
                );

            // Envoy_eKonto
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_ekonto"
                , @"Metadata\PaymentMethod\Envoy_eKonto\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_ekonto"
                , @"Metadata\PaymentMethod\Envoy_eKonto\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_ekonto"
                , @"Metadata\PaymentMethod\Envoy_eKonto\.Withdraw_Message"
                );

            // Envoy_eWire
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_ewiredk"
                , @"Metadata\PaymentMethod\Envoy_eWire\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_ewiredk"
                , @"Metadata\PaymentMethod\Envoy_eWire\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_ewiredk"
                , @"Metadata\PaymentMethod\Envoy_eWire\.Withdraw_Message"
                );

            // Envoy_Euteller
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_euteller"
                , @"Metadata\PaymentMethod\Envoy_Euteller\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_euteller"
                , @"Metadata\PaymentMethod\Envoy_Euteller\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_euteller"
                , @"Metadata\PaymentMethod\Envoy_Euteller\.Withdraw_Message"
                );

            // Envoy_WebMoney
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_webmoney"
                , @"Metadata\PaymentMethod\Envoy_WebMoney\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_webmoney"
                , @"Metadata\PaymentMethod\Envoy_WebMoney\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_webmoney"
                , @"Metadata\PaymentMethod\Envoy_WebMoney\.Withdraw_Message"
                );

            // Envoy_MultiBanco
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_multibanco"
                , @"Metadata\PaymentMethod\Envoy_MultiBanco\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_multibanco"
                , @"Metadata\PaymentMethod\Envoy_MultiBanco\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_multibanco"
                , @"Metadata\PaymentMethod\Envoy_MultiBanco\.Withdraw_Message"
                );

            // Envoy_Teleingreso
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_teleingreso"
                , @"Metadata\PaymentMethod\Envoy_Teleingreso\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_teleingreso"
                , @"Metadata\PaymentMethod\Envoy_Teleingreso\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_teleingreso"
                , @"Metadata\PaymentMethod\Envoy_Teleingreso\.Withdraw_Message"
                );

            // Envoy_EPS
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_eps"
                , @"Metadata\PaymentMethod\Envoy_EPS\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_eps"
                , @"Metadata\PaymentMethod\Envoy_EPS\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_eps"
                , @"Metadata\PaymentMethod\Envoy_EPS\.Withdraw_Message"
                );

            // Envoy_GiroPay
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_giropay"
                , @"Metadata\PaymentMethod\Envoy_GiroPay\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_giropay"
                , @"Metadata\PaymentMethod\Envoy_GiroPay\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_giropay"
                , @"Metadata\PaymentMethod\Envoy_GiroPay\.Withdraw_Message"
                );

            // Envoy_InstaDebit
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_instadebit"
                , @"Metadata\PaymentMethod\Envoy_InstaDebit\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_instadebit"
                , @"Metadata\PaymentMethod\Envoy_InstaDebit\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_instadebit"
                , @"Metadata\PaymentMethod\Envoy_InstaDebit\.Withdraw_Message"
                );

            // Envoy_Nordea
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_banklinknordea"
                , @"Metadata\PaymentMethod\Envoy_Nordea\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_banklinknordea"
                , @"Metadata\PaymentMethod\Envoy_Nordea\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_banklinknordea"
                , @"Metadata\PaymentMethod\Envoy_Nordea\.Withdraw_Message"
                );

            // Envoy_Neosurf
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_neosurf"
                , @"Metadata\PaymentMethod\Envoy_Neosurf\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_neosurf"
                , @"Metadata\PaymentMethod\Envoy_Neosurf\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_neosurf"
                , @"Metadata\PaymentMethod\Envoy_Neosurf\.Withdraw_Message"
                );

            // Envoy_DineroMail
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_dineromail"
                , @"Metadata\PaymentMethod\Envoy_DineroMail\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_dineromail"
                , @"Metadata\PaymentMethod\Envoy_DineroMail\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_dineromail"
                , @"Metadata\PaymentMethod\Envoy_DineroMail\.Withdraw_Message"
                );

            // Envoy_ToditoCard
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_toditocard"
                , @"Metadata\PaymentMethod\Envoy_ToditoCard\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_toditocard"
                , @"Metadata\PaymentMethod\Envoy_ToditoCard\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_toditocard"
                , @"Metadata\PaymentMethod\Envoy_ToditoCard\.Withdraw_Message"
                );

            // Envoy_LobaNet
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_lobanet"
                , @"Metadata\PaymentMethod\Envoy_LobaNet\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_lobanet"
                , @"Metadata\PaymentMethod\Envoy_LobaNet\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_lobanet"
                , @"Metadata\PaymentMethod\Envoy_LobaNet\.Withdraw_Message"
                );

            // Envoy_CuentaDigital
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_cuentadigital"
                , @"Metadata\PaymentMethod\Envoy_CuentaDigital\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_cuentadigital"
                , @"Metadata\PaymentMethod\Envoy_CuentaDigital\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_cuentadigital"
                , @"Metadata\PaymentMethod\Envoy_CuentaDigital\.Withdraw_Message"
                );

            // Envoy_Santander
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_bancosantander"
                , @"Metadata\PaymentMethod\Envoy_Santander\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_bancosantander"
                , @"Metadata\PaymentMethod\Envoy_Santander\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_bancosantander"
                , @"Metadata\PaymentMethod\Envoy_Santander\.Withdraw_Message"
                );

            // Envoy_GluePay
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_gluepay"
                , @"Metadata\PaymentMethod\Envoy_GluePay\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_gluepay"
                , @"Metadata\PaymentMethod\Envoy_GluePay\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_gluepay"
                , @"Metadata\PaymentMethod\Envoy_GluePay\.Withdraw_Message"
                );

            // Envoy_ePayBg
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_epay"
                , @"Metadata\PaymentMethod\Envoy_ePayBg\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_epay"
                , @"Metadata\PaymentMethod\Envoy_ePayBg\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_epay"
                , @"Metadata\PaymentMethod\Envoy_ePayBg\.Withdraw_Message"
                );

            // Envoy_CashU
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_cashu"
                , @"Metadata\PaymentMethod\Envoy_CashU\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_cashu"
                , @"Metadata\PaymentMethod\Envoy_CashU\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_cashu"
                , @"Metadata\PaymentMethod\Envoy_CashU\.Withdraw_Message"
                );

            // Envoy_PagoFacil
            CopyResource(@"App_GlobalResources\PaymentTitle.resx"
                , "envoy_pagofacil"
                , @"Metadata\PaymentMethod\Envoy_PagoFacil\.Title"
                );
            CopyResource(@"App_GlobalResources\PaymentShortDescription.resx"
                , "envoy_pagofacil"
                , @"Metadata\PaymentMethod\Envoy_PagoFacil\.Description"
                );
            CopyResource(@"App_GlobalResources\PaymentWithdrawDescription.resx"
                , "envoy_pagofacil"
                , @"Metadata\PaymentMethod\Envoy_PagoFacil\.Withdraw_Message"
                );
            */
        }

        private static void CopyAccountBox()
        {
            CopyResource(@"opCommon\App_LocalResources\MasterAccountInfo.ascx.resx"
                , "Welcome"
                , @"Head\_Welcome_ascx\.TEXT"
                );
            CopyResource(@"opCommon\App_LocalResources\MasterLogout.ascx.resx"
                , "Logout_Button"
                , @"Head\_Logout_ascx\.BUTTON_TEXT"
                );
            CopyResource(@"opCommon\App_LocalResources\MasterAccountInfo.ascx.resx"
                , "Deposit"
                , @"Head\_Deposit_ascx\.BUTTON_TEXT"
                );
            CopyResource(@"opCommon\App_LocalResources\MasterAccountInfo.ascx.resx"
                , "Transfer"
                , @"Head\_Transfer_ascx\.BUTTON_TEXT"
                );
        }

        private static void CopyBalance()
        {
            CreateMetadata(@"Metadata\GammingAccount\CakeNetwork");
            CopyResource(@"App_GlobalResources\AccountName.resx"
                , "CakeNetwork"
                , @"Metadata\GammingAccount\CakeNetwork\.Display_Name"
                );
            CreateMetadata(@"Metadata\GammingAccount\GutsGames");
            CopyResource(@"App_GlobalResources\AccountName.resx"
                , "GutsGames"
                , @"Metadata\GammingAccount\GutsGames\.Display_Name"
                );
            CreateMetadata(@"Metadata\GammingAccount\NetEnt");
            CopyResource(@"App_GlobalResources\AccountName.resx"
                , "NetEnt"
                , @"Metadata\GammingAccount\NetEnt\.Display_Name"
                );
            CreateMetadata(@"Metadata\GammingAccount\OddsMatrix");
            CopyResource(@"App_GlobalResources\AccountName.resx"
                , "OddsMatrix"
                , @"Metadata\GammingAccount\OddsMatrix\.Display_Name"
                );
            CreateMetadata(@"Metadata\GammingAccount\OnGame");
            CopyResource(@"App_GlobalResources\AccountName.resx"
                , "OnGame"
                , @"Metadata\GammingAccount\OnGame\.Display_Name"
                );
            CreateMetadata(@"Metadata\GammingAccount\System");
            CopyResource(@"App_GlobalResources\AccountName.resx"
                , "System"
                , @"Metadata\GammingAccount\System\.Display_Name"
                );

            CopyResource(@"opCommon\App_LocalResources\Balances.ascx.resx"
                , "Loading_Balances"
                , @"Head\_BalanceList_ascx\.Loading_Balances"
                );
            CopyResource(@"opCommon\App_LocalResources\Balances.ascx.resx"
                , "Failed"
                , @"Head\_BalanceList_ascx\.Load_Balances_Failed"
                );
        }

        private static void CopyMasterLogin()
        {
            CopyResource(@"opCommon\App_LocalResources\MasterLogin.ascx.resx"
                , "UsernameOrPassword_Missing"
                , @"Head\_LoginPane_ascx\.UsernamePassword_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\MasterLogin.ascx.resx"
                , "BtnLogin"
                , @"Head\_LoginPane_ascx\.Login_Btn_Text"
                );
            CopyResource(@"opCommon\App_LocalResources\MasterLogin.ascx.resx"
                , "UsernameWatermark"
                , @"Head\_LoginPane_ascx\.Username_Wartermark"
                );
            CopyResource(@"opCommon\App_LocalResources\MasterLogin.ascx.resx"
                , "PasswordWatermark"
                , @"Head\_LoginPane_ascx\.Password_Wartermark"
                );
            CopyResource(@"opCommon\App_LocalResources\MasterLogin.ascx.resx"
                , "LoginFailed"
                , @"Head\_LoginPane_ascx\.UsernamePassword_Invalid"
                );
            CopyResource(@"opCommon\App_LocalResources\MasterLogin.ascx.resx"
                , "LoginBlocked"
                , @"Head\_LoginPane_ascx\.Login_Blocked"
                );
            CopyResource(@"opCommon\App_LocalResources\MasterLogin.ascx.resx"
                , "TooManyInvalidAttempts"
                , @"Head\_LoginPane_ascx\.Login_TooManyInvalidAttempts"
                );
            CopyResource(@"opCommon\App_LocalResources\MasterLogin.ascx.resx"
                , "ForgotPassword"
                , @"Head\_ForgotPassword_ascx\.LINK_TEXT"
                );
            CopyResource(@"opCommon\App_LocalResources\MasterHeader.ascx.resx"
                , "Signup"
                , @"Head\_SignUp_ascx\.LINK_TEXT"
                );

            CopyResource(@"opCommon\App_LocalResources\Default.master.resx"
                , "IE6Message"
                , @"_RootMaster_master\.IE6_Message"
                );
        }

        #region Security Questions
        private static void CopySecurityQuestion()
        {
            CreateMetadata(@"Metadata\SecurityQuestion\MyFavouriteBet");
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Question_MyFavouriteBet"
                , @"Metadata\SecurityQuestion\MyFavouriteBet\.Text"
                );

            CreateMetadata(@"Metadata\SecurityQuestion\MyFavouriteColor");
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Question_MyFavouriteColor"
                , @"Metadata\SecurityQuestion\MyFavouriteColor\.Text"
                );

            CreateMetadata(@"Metadata\SecurityQuestion\MyFavouriteHorse");
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Question_MyFavouriteHorse"
                , @"Metadata\SecurityQuestion\MyFavouriteHorse\.Text"
                );

            CreateMetadata(@"Metadata\SecurityQuestion\MyFavouritePlace");
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Question_MyFavouritePlace"
                , @"Metadata\SecurityQuestion\MyFavouritePlace\.Text"
                );

            CreateMetadata(@"Metadata\SecurityQuestion\MyFavouriteSuperHero");
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Question_MyFavouriteSuperHero"
                , @"Metadata\SecurityQuestion\MyFavouriteSuperHero\.Text"
                );

            CreateMetadata(@"Metadata\SecurityQuestion\MyFavouriteTeam");
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Question_MyFavouriteTeam"
                , @"Metadata\SecurityQuestion\MyFavouriteTeam\.Text"
                );

            CreateMetadata(@"Metadata\SecurityQuestion\MyMiddleName");
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Question_MyMiddleName"
                , @"Metadata\SecurityQuestion\MyMiddleName\.Text"
                );

            CreateMetadata(@"Metadata\SecurityQuestion\MyMothersMaidenName");
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Question_MyMothersMaidenName"
                , @"Metadata\SecurityQuestion\MyMothersMaidenName\.Text"
                );

            CreateMetadata(@"Metadata\SecurityQuestion\MyPetsName");
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Question_MyPetsName"
                , @"Metadata\SecurityQuestion\MyPetsName\.Text"
                );
        }
        #endregion

        #region Currency
        private static void CopyCurrency()
        {
            CopyResource(@"App_GlobalResources\Currencies.resx"
                , "CNY"
                , @"Metadata\Currency\CNY\.Display_Name"
                );
            CopyResource(@"App_GlobalResources\Currencies.resx"
                , "CZK"
                , @"Metadata\Currency\CZK\.Display_Name"
                );
            CopyResource(@"App_GlobalResources\Currencies.resx"
                , "DKK"
                , @"Metadata\Currency\DKK\.Display_Name"
                );
            CopyResource(@"App_GlobalResources\Currencies.resx"
                , "EUR"
                , @"Metadata\Currency\EUR\.Display_Name"
                );
            CopyResource(@"App_GlobalResources\Currencies.resx"
                , "GBP"
                , @"Metadata\Currency\GBP\.Display_Name"
                );
            CopyResource(@"App_GlobalResources\Currencies.resx"
                , "ILS"
                , @"Metadata\Currency\ILS\.Display_Name"
                );
            CopyResource(@"App_GlobalResources\Currencies.resx"
                , "NOK"
                , @"Metadata\Currency\NOK\.Display_Name"
                );
            CopyResource(@"App_GlobalResources\Currencies.resx"
                , "PLN"
                , @"Metadata\Currency\PLN\.Display_Name"
                );
            CopyResource(@"App_GlobalResources\Currencies.resx"
                , "RUB"
                , @"Metadata\Currency\RUB\.Display_Name"
                );
            CopyResource(@"App_GlobalResources\Currencies.resx"
                , "SEK"
                , @"Metadata\Currency\SEK\.Display_Name"
                );
            CopyResource(@"App_GlobalResources\Currencies.resx"
                , "USD"
                , @"Metadata\Currency\USD\.Display_Name"
                );
            CopyResource(@"App_GlobalResources\Currencies.resx"
                , "ZAR"
                , @"Metadata\Currency\ZAR\.Display_Name"
                );
        }
        #endregion

        #region Title
        private static void CopyTitle()
        {
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Title_Miss"
                , @"Metadata\Title\.Miss"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Title_Mr"
                , @"Metadata\Title\.Mr"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Title_Mrs"
                , @"Metadata\Title\.Mrs"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Title_Ms"
                , @"Metadata\Title\.Ms"
                );
        }
        #endregion

        #region Register Complete
        private static void CopyRegisterComplete()
        {
            CopyResource(@"opCommon\App_LocalResources\RegistrationComplete.ascx.resx"
                , "RegistrationComplete"
                , @"Register\_ActivationSucceed_ascx\.Success_Message"
                );

            CopyResource(@"opCommon\App_LocalResources\RegistrationComplete.ascx.resx"
                , "Wrong_Text1"
                , @"Register\_ActivationFailed_ascx\.Failed_Message"
                );

            CopyResource(@"opCommon\App_LocalResources\RegistrationComplete.ascx.resx"
                , "Signup"
                , @"Register\_ActivationFailed_ascx\.SignUp_Button"
                );

            CopyResource(@"opCommon\App_LocalResources\RegistrationComplete.ascx.resx"
                , "Wrong_Text3"
                , @"Register\_ActivationFailed_ascx\.SignUp_Here"
                );

            CopyResource(@"opCommon\App_LocalResources\RegistrationComplete.ascx.resx"
                , "Wrong_Text2"
                , @"Register\_ActivationExpiried_ascx\.Expiried_Message"
                );

            CopyResource(@"opCommon\App_LocalResources\RegistrationComplete.ascx.resx"
                , "RegistrationComplete_Header"
                , @"Register\_Activate_aspx\.Head_Text"
                );            
        }
        #endregion

        #region Register
        private static void CopyRegister()
        {
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "BeyondLimit_Message"
                , @"Register\_MaxSameIPRegistrationExceededView_ascx\.Blocked_Message"
                );

            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Blocked_Message"
                , @"Register\_CountryBlockedView_ascx\.Blocked_Message"
                );

            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Title"
                , @"Register\_PersionalInformation_ascx\.Title_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Title_Missing"
                , @"Register\_PersionalInformation_ascx\.Title_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Title_Choose"
                , @"Register\_PersionalInformation_ascx\.Title_Choose"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "FirstName"
                , @"Register\_PersionalInformation_ascx\.Firstname_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "FirstNameIllegal"
                , @"Register\_PersionalInformation_ascx\.Firstname_Illegal"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "FirstNameEmpty"
                , @"Register\_PersionalInformation_ascx\.FirstName_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "FirstNameLimit"
                , @"Register\_PersionalInformation_ascx\.FirstName_MinLength"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Surname"
                , @"Register\_PersionalInformation_ascx\.Surname_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "SurnameEmpty"
                , @"Register\_PersionalInformation_ascx\.Surname_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "SurnameIllegal"
                , @"Register\_PersionalInformation_ascx\.Surname_Illegal"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Email"
                , @"Register\_PersionalInformation_ascx\.Email_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "rfvEmail"
                , @"Register\_PersionalInformation_ascx\.Email_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "revEmail"
                , @"Register\_PersionalInformation_ascx\.Email_Incorrect"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "cvEmailUnique"
                , @"Register\_PersionalInformation_ascx\.Email_Exist"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "DOB"
                , @"Register\_PersionalInformation_ascx\.DOB_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "DOB_Day"
                , @"Register\_PersionalInformation_ascx\.DOB_Day"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "DOB_Month"
                , @"Register\_PersionalInformation_ascx\.DOB_Month"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "DOB_Year"
                , @"Register\_PersionalInformation_ascx\.DOB_Year"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "DOB_NotLegalAge"
                , @"Register\_PersionalInformation_ascx\.DOB_Under18"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "DOB_Invalid"
                , @"Register\_PersionalInformation_ascx\.DOB_Empty"
                );


            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Country"
                , @"Register\_AddressInformation_ascx\.Country_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Country_Missing"
                , @"Register\_AddressInformation_ascx\.Country_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Country_Select"
                , @"Register\_AddressInformation_ascx\.Country_Select"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Region"
               , @"Register\_AddressInformation_ascx\.Region_Label"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Region_Select"
               , @"Register\_AddressInformation_ascx\.Region_Select"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Region_Missing"
               , @"Register\_AddressInformation_ascx\.Region_Empty"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "BillingAddress1"
                , @"Register\_AddressInformation_ascx\.Address1_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "BillingAddress1_Missing"
                , @"Register\_AddressInformation_ascx\.Address1_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "BillingAddress2"
                , @"Register\_AddressInformation_ascx\.Address2_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "BillingAddressLimit"
                , @"Register\_AddressInformation_ascx\.Address_MinLength"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "City"
                , @"Register\_AddressInformation_ascx\.City_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "City_Missing"
                , @"Register\_AddressInformation_ascx\.City_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "CityLimit"
                , @"Register\_AddressInformation_ascx\.City_MinLength"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "PostCode"
                , @"Register\_AddressInformation_ascx\.PostalCode_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "PostCode_Missing"
                , @"Register\_AddressInformation_ascx\.PostalCode_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Mobile"
                , @"Register\_AddressInformation_ascx\.Mobile_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Mobile_Missing"
                , @"Register\_AddressInformation_ascx\.Mobile_Empty"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Mobile_Invalid"
                , @"Register\_AddressInformation_ascx\.Mobile_Incorrect"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
                , "Phone"
                , @"Register\_AddressInformation_ascx\.Phone_Label"
                );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Phone_Missing"
               , @"Register\_AddressInformation_ascx\.Phone_Empty"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Phone_Invalid"
               , @"Register\_AddressInformation_ascx\.Phone_Incorrect"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "PhonePrefix"
               , @"Register\_AddressInformation_ascx\.PhonePrefix"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "PhonePrefix_Missing"
               , @"Register\_AddressInformation_ascx\.PhonePrefix_Empty"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "PhonePrefix_Select"
               , @"Register\_AddressInformation_ascx\.PhonePrefix_Select"
               );

            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Avatar"
               , @"Register\_AccountInformation_ascx\.Avatar_Label"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Change"
               , @"Register\_AccountInformation_ascx\.Avatar_Change"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "LoginName"
               , @"Register\_AccountInformation_ascx\.Username_Label"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "LoginName_Missing"
               , @"Register\_AccountInformation_ascx\.Username_Empty"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "LoginName_NotAvailable"
               , @"Register\_AccountInformation_ascx\.Username_Exist"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "LoginNameLimit"
               , @"Register\_AccountInformation_ascx\.Username_Length"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "LoginName_Invalid"
               , @"Register\_AccountInformation_ascx\.Username_Illegal"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Alias"
               , @"Register\_AccountInformation_ascx\.Alias_Label"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "AliasMissing"
               , @"Register\_AccountInformation_ascx\.Alias_Empty"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "AliasLimit"
               , @"Register\_AccountInformation_ascx\.Alias_Length"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "AliasExists"
               , @"Register\_AccountInformation_ascx\.Alias_Exist"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Password"
               , @"Register\_AccountInformation_ascx\.Password_Label"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Password_Missing"
               , @"Register\_AccountInformation_ascx\.Password_Empty"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Password_Invalid"
               , @"Register\_AccountInformation_ascx\.Password_Incorrect"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "PasswordRep"
               , @"Register\_AccountInformation_ascx\.RepeatPassword_Label"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "PasswordRep_Missing"
               , @"Register\_AccountInformation_ascx\.RepeatPassword_Empty"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "PasswordRep_NotCorrect"
               , @"Register\_AccountInformation_ascx\.RepeatPassword_NotMatch"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Currency"
               , @"Register\_AccountInformation_ascx\.Currency_Label"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Currency_Missing"
               , @"Register\_AccountInformation_ascx\.Currency_Empty"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Currency_Select"
               , @"Register\_AccountInformation_ascx\.Currency_Select"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Question"
               , @"Register\_AccountInformation_ascx\.SecurityQuestion_Label"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Question_Missing"
               , @"Register\_AccountInformation_ascx\.SecurityQuestion_Empty"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Question_Select"
               , @"Register\_AccountInformation_ascx\.SecurityQuestion_Select"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Answer"
               , @"Register\_AccountInformation_ascx\.SecurityAnswer_Label"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Answer_Missing"
               , @"Register\_AccountInformation_ascx\.SecurityAnswer_Empty"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "AnswerLimit"
               , @"Register\_AccountInformation_ascx\.SecurityAnswer_MinLength"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "Language"
               , @"Register\_AccountInformation_ascx\.Language_Label"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "PromoCode"
               , @"Register\_AccountInformation_ascx\.PromoCode_Label"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
               , "PromoCode_Expired"
               , @"Register\_AccountInformation_ascx\.PromoCode_Expired"
               );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
              , "PromoCode_Invalid"
              , @"Register\_AccountInformation_ascx\.PromoCode_Invalid"
              );

            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
              , "Fields_Personal"
              , @"Register\_InputView_ascx\.Personal_Information"
              );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
              , "Fields_Address"
              , @"Register\_InputView_ascx\.Address_Information"
              );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
              , "Fields_AccountInfo"
              , @"Register\_InputView_ascx\.Account_Information"
              );

            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
              , "Header_Registration"
              , @"Register\_Index_aspx\.Head_Text"
              );

            // _AdditionalInformation_ascx
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
              , "NewsAndOffers_Yes"
              , @"Register\_AdditionalInformation_ascx\.NewsOffers_Label"
              );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
              , "ConfirmAge_IHaveLegalAge"
              , @"Register\_AdditionalInformation_ascx\.LegalAge_Label"
              );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
              , "TC_IHaveRead"
              , @"Register\_AdditionalInformation_ascx\.TermsConditions_Label"
              );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
              , "TC_LinkText"
              , @"Register\_AdditionalInformation_ascx\.TermsConditions_Link"
              );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
              , "TC_Missing"
              , @"Register\_AdditionalInformation_ascx\.TermsConditions_Error"
              );
            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
              , "ConfirmAge_Missing"
              , @"Register\_AdditionalInformation_ascx\.LegalAge_Error"
              );

            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
              , "Button_Register"
              , @"Register\_InputView_ascx\.Register_Button"
              );

            CopyResource(@"opCommon\App_LocalResources\Register.ascx.resx"
              , "Done_EmailSent"
              , @"Register\_SuccessView_ascx\.Success_Message"
              );
        }
        #endregion

        #region Countries
        private static void CopyCountries()
        {
            List<CountryInfo> countries = new List<CountryInfo>();

            #region initialize the countries
            countries.Add(new CountryInfo() { InternalID = 8, EnglishName = "Afghanistan", ISO_3166_Name = @"AFGHANISTAN", ISO_3166_Alpha2Code = "AF", ISO_3166_Alpha3Code = "AFG", PhoneCode = "+93", CurrencyCode = "AFA", NetEntCountryName = "AFGHANISTAN" });
            countries.Add(new CountryInfo() { InternalID = 9, EnglishName = "Albania", ISO_3166_Name = @"ALBANIA", ISO_3166_Alpha2Code = "AL", ISO_3166_Alpha3Code = "ALB", PhoneCode = "+355", CurrencyCode = "ALL", NetEntCountryName = "ALBANIA" });
            countries.Add(new CountryInfo() { InternalID = 10, EnglishName = "Algeria", ISO_3166_Name = @"ALGERIA", ISO_3166_Alpha2Code = "DZ", ISO_3166_Alpha3Code = "DZA", PhoneCode = "+213", CurrencyCode = "DZD", NetEntCountryName = "ALGERIA" });
            countries.Add(new CountryInfo() { InternalID = 11, EnglishName = "American Samoa", ISO_3166_Name = @"AMERICAN SAMOA", ISO_3166_Alpha2Code = "AS", ISO_3166_Alpha3Code = "ASM", PhoneCode = "+684", CurrencyCode = "EUR", NetEntCountryName = "AMERICAN SAMOA" });
            countries.Add(new CountryInfo() { InternalID = 12, EnglishName = "Andorra", ISO_3166_Name = @"ANDORRA", ISO_3166_Alpha2Code = "AD", ISO_3166_Alpha3Code = "AND", PhoneCode = "+376", CurrencyCode = "EUR", NetEntCountryName = "ANDORRA" });
            countries.Add(new CountryInfo() { InternalID = 13, EnglishName = "Angola", ISO_3166_Name = @"ANGOLA", ISO_3166_Alpha2Code = "AO", ISO_3166_Alpha3Code = "AGO", PhoneCode = "+244", CurrencyCode = "AOK", NetEntCountryName = "ANGOLA" });
            countries.Add(new CountryInfo() { InternalID = 14, EnglishName = "Anguilla", ISO_3166_Name = @"ANGUILLA", ISO_3166_Alpha2Code = "AI", ISO_3166_Alpha3Code = "AIA", PhoneCode = "+1-264", CurrencyCode = "XCD", NetEntCountryName = "ANGUILLA" });
            countries.Add(new CountryInfo() { InternalID = 15, EnglishName = "Antarctica", ISO_3166_Name = @"ANTARCTICA", ISO_3166_Alpha2Code = "AQ", ISO_3166_Alpha3Code = "   ", PhoneCode = "+672", CurrencyCode = "", NetEntCountryName = "ANTARCTICA" });
            countries.Add(new CountryInfo() { InternalID = 16, EnglishName = "Antigua and Barbuda", ISO_3166_Name = @"ANTIGUA AND BARBUDA", ISO_3166_Alpha2Code = "AG", ISO_3166_Alpha3Code = "ATG", PhoneCode = "+1-268", CurrencyCode = "XCD", NetEntCountryName = "ANTIGUA AND BARBUDA" });
            countries.Add(new CountryInfo() { InternalID = 17, EnglishName = "Argentina", ISO_3166_Name = @"ARGENTINA", ISO_3166_Alpha2Code = "AR", ISO_3166_Alpha3Code = "ARG", PhoneCode = "+54", CurrencyCode = "ARP", NetEntCountryName = "ARGENTINA" });
            countries.Add(new CountryInfo() { InternalID = 18, EnglishName = "Armenia", ISO_3166_Name = @"ARMENIA", ISO_3166_Alpha2Code = "AM", ISO_3166_Alpha3Code = "ARM", PhoneCode = "+374", CurrencyCode = "AMD", NetEntCountryName = "ARMENIA" });
            countries.Add(new CountryInfo() { InternalID = 19, EnglishName = "Aruba", ISO_3166_Name = @"ARUBA", ISO_3166_Alpha2Code = "AW", ISO_3166_Alpha3Code = "ABW", PhoneCode = "+297", CurrencyCode = "ANG", NetEntCountryName = "ARUBA" });
            countries.Add(new CountryInfo() { InternalID = 20, EnglishName = "Australia", ISO_3166_Name = @"AUSTRALIA", ISO_3166_Alpha2Code = "AU", ISO_3166_Alpha3Code = "AUS", PhoneCode = "+61", CurrencyCode = "AUD", NetEntCountryName = "AUSTRALIA" });
            countries.Add(new CountryInfo() { InternalID = 21, EnglishName = "Austria", ISO_3166_Name = @"AUSTRIA", ISO_3166_Alpha2Code = "AT", ISO_3166_Alpha3Code = "AUT", PhoneCode = "+43", CurrencyCode = "EUR", NetEntCountryName = "AUSTRIA" });
            countries.Add(new CountryInfo() { InternalID = 22, EnglishName = "Azerbaijan", ISO_3166_Name = @"AZERBAIJAN", ISO_3166_Alpha2Code = "AZ", ISO_3166_Alpha3Code = "AZE", PhoneCode = "+994", CurrencyCode = "AZM", NetEntCountryName = "AZERBAIJAN" });
            countries.Add(new CountryInfo() { InternalID = 23, EnglishName = "Bahamas", ISO_3166_Name = @"BAHAMAS", ISO_3166_Alpha2Code = "BS", ISO_3166_Alpha3Code = "BHS", PhoneCode = "+1-242", CurrencyCode = "BSD", NetEntCountryName = "THE BAHAMAS" });
            countries.Add(new CountryInfo() { InternalID = 24, EnglishName = "Bahrain", ISO_3166_Name = @"BAHRAIN", ISO_3166_Alpha2Code = "BH", ISO_3166_Alpha3Code = "BHR", PhoneCode = "+973", CurrencyCode = "BHD", NetEntCountryName = "BAHRAIN" });
            countries.Add(new CountryInfo() { InternalID = 25, EnglishName = "Bangladesh", ISO_3166_Name = @"BANGLADESH", ISO_3166_Alpha2Code = "BD", ISO_3166_Alpha3Code = "BGD", PhoneCode = "+880", CurrencyCode = "BDT", NetEntCountryName = "BANGLADESH" });
            countries.Add(new CountryInfo() { InternalID = 26, EnglishName = "Barbados", ISO_3166_Name = @"BARBADOS", ISO_3166_Alpha2Code = "BB", ISO_3166_Alpha3Code = "BRB", PhoneCode = "+1-246", CurrencyCode = "BBD", NetEntCountryName = "BARBADOS" });
            countries.Add(new CountryInfo() { InternalID = 27, EnglishName = "Belarus", ISO_3166_Name = @"BELARUS", ISO_3166_Alpha2Code = "BY", ISO_3166_Alpha3Code = "BLR", PhoneCode = "+375", CurrencyCode = "BYR", NetEntCountryName = "BELARUS" });
            countries.Add(new CountryInfo() { InternalID = 28, EnglishName = "Belgium", ISO_3166_Name = @"BELGIUM", ISO_3166_Alpha2Code = "BE", ISO_3166_Alpha3Code = "BEL", PhoneCode = "+32", CurrencyCode = "EUR", NetEntCountryName = "BELGIUM" });
            countries.Add(new CountryInfo() { InternalID = 29, EnglishName = "Belize", ISO_3166_Name = @"BELIZE", ISO_3166_Alpha2Code = "BZ", ISO_3166_Alpha3Code = "BLZ", PhoneCode = "+501", CurrencyCode = "BZD", NetEntCountryName = "BELIZE" });
            countries.Add(new CountryInfo() { InternalID = 30, EnglishName = "Benin", ISO_3166_Name = @"BENIN", ISO_3166_Alpha2Code = "BJ", ISO_3166_Alpha3Code = "BEN", PhoneCode = "+229", CurrencyCode = "XOF", NetEntCountryName = "BENIN" });
            countries.Add(new CountryInfo() { InternalID = 31, EnglishName = "Bermuda", ISO_3166_Name = @"BERMUDA", ISO_3166_Alpha2Code = "BM", ISO_3166_Alpha3Code = "BMU", PhoneCode = "+1-441", CurrencyCode = "BMD", NetEntCountryName = "BERMUDA" });
            countries.Add(new CountryInfo() { InternalID = 32, EnglishName = "Bhutan", ISO_3166_Name = @"BHUTAN", ISO_3166_Alpha2Code = "BT", ISO_3166_Alpha3Code = "BTN", PhoneCode = "+975", CurrencyCode = "INR", NetEntCountryName = "BHUTAN" });
            countries.Add(new CountryInfo() { InternalID = 33, EnglishName = "Bolivia", ISO_3166_Name = @"BOLIVIA", ISO_3166_Alpha2Code = "BO", ISO_3166_Alpha3Code = "BOL", PhoneCode = "+591", CurrencyCode = "BOB", NetEntCountryName = "BOLIVIA" });
            countries.Add(new CountryInfo() { InternalID = 34, EnglishName = "Bosnia and Herzegovina", ISO_3166_Name = @"BOSNIA AND HERZEGOVINA", ISO_3166_Alpha2Code = "BA", ISO_3166_Alpha3Code = "BIH", PhoneCode = "+387", CurrencyCode = "BAK", NetEntCountryName = "BOSNIA AND HERZEGOVINA" });
            countries.Add(new CountryInfo() { InternalID = 35, EnglishName = "Botswana", ISO_3166_Name = @"BOTSWANA", ISO_3166_Alpha2Code = "BW", ISO_3166_Alpha3Code = "BWA", PhoneCode = "+267", CurrencyCode = "BWP", NetEntCountryName = "BOTSWANA" });
            countries.Add(new CountryInfo() { InternalID = 36, EnglishName = "Bouvet Island", ISO_3166_Name = @"BOUVET ISLAND", ISO_3166_Alpha2Code = "BV", ISO_3166_Alpha3Code = "   ", PhoneCode = "+???", CurrencyCode = "NOK", NetEntCountryName = "BOUVET ISLAND" });
            countries.Add(new CountryInfo() { InternalID = 37, EnglishName = "Brazil", ISO_3166_Name = @"BRAZIL", ISO_3166_Alpha2Code = "BR", ISO_3166_Alpha3Code = "BRA", PhoneCode = "+55", CurrencyCode = "BRR", NetEntCountryName = "BRAZIL" });
            countries.Add(new CountryInfo() { InternalID = 38, EnglishName = "British Indian Ocean Territory", ISO_3166_Name = @"BRITISH INDIAN OCEAN TERRITORY", ISO_3166_Alpha2Code = "IO", ISO_3166_Alpha3Code = "   ", PhoneCode = "+246", CurrencyCode = "USD", NetEntCountryName = "BRITISH INDIAN OCEAN TERRITORY" });
            countries.Add(new CountryInfo() { InternalID = 39, EnglishName = "Brunei Darussalam", ISO_3166_Name = @"BRUNEI DARUSSALAM", ISO_3166_Alpha2Code = "BN", ISO_3166_Alpha3Code = "BRN", PhoneCode = "+673", CurrencyCode = "BND", NetEntCountryName = "BRUNEI DARUSSALAM" });
            countries.Add(new CountryInfo() { InternalID = 40, EnglishName = "Bulgaria", ISO_3166_Name = @"BULGARIA", ISO_3166_Alpha2Code = "BG", ISO_3166_Alpha3Code = "BGR", PhoneCode = "+359", CurrencyCode = "BGL", NetEntCountryName = "BULGARIA" });
            countries.Add(new CountryInfo() { InternalID = 41, EnglishName = "Burkina Faso", ISO_3166_Name = @"BURKINA FASO", ISO_3166_Alpha2Code = "BF", ISO_3166_Alpha3Code = "BFA", PhoneCode = "+226", CurrencyCode = "XOF", NetEntCountryName = "BURKINA FASO" });
            countries.Add(new CountryInfo() { InternalID = 42, EnglishName = "Burundi", ISO_3166_Name = @"BURUNDI", ISO_3166_Alpha2Code = "BI", ISO_3166_Alpha3Code = "BDI", PhoneCode = "+257", CurrencyCode = "BIF", NetEntCountryName = "BURUNDI" });
            countries.Add(new CountryInfo() { InternalID = 43, EnglishName = "Cambodia", ISO_3166_Name = @"CAMBODIA", ISO_3166_Alpha2Code = "KH", ISO_3166_Alpha3Code = "KHM", PhoneCode = "+855", CurrencyCode = "KHR", NetEntCountryName = "CAMBODIA" });
            countries.Add(new CountryInfo() { InternalID = 44, EnglishName = "Cameroon", ISO_3166_Name = @"CAMEROON", ISO_3166_Alpha2Code = "CM", ISO_3166_Alpha3Code = "CMR", PhoneCode = "+237", CurrencyCode = "XAF", NetEntCountryName = "CAMEROON" });
            countries.Add(new CountryInfo() { InternalID = 45, EnglishName = "Canada", ISO_3166_Name = @"CANADA", ISO_3166_Alpha2Code = "CA", ISO_3166_Alpha3Code = "CAN", PhoneCode = "+1", CurrencyCode = "CAD", NetEntCountryName = "CANADA" });
            countries.Add(new CountryInfo() { InternalID = 46, EnglishName = "Cape Verde", ISO_3166_Name = @"CAPE VERDE", ISO_3166_Alpha2Code = "CV", ISO_3166_Alpha3Code = "CPV", PhoneCode = "+238", CurrencyCode = "CVE", NetEntCountryName = "CAPE VERDE" });
            countries.Add(new CountryInfo() { InternalID = 47, EnglishName = "Cayman Islands", ISO_3166_Name = @"CAYMAN ISLANDS", ISO_3166_Alpha2Code = "KY", ISO_3166_Alpha3Code = "CYM", PhoneCode = "+1-345", CurrencyCode = "KYD", NetEntCountryName = "CAYMAN ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 48, EnglishName = "Central African Republic", ISO_3166_Name = @"CENTRAL AFRICAN REPUBLIC", ISO_3166_Alpha2Code = "CF", ISO_3166_Alpha3Code = "CAF", PhoneCode = "+236", CurrencyCode = "XAF", NetEntCountryName = "CENTRAL AFRICAN REPUBLIC" });
            countries.Add(new CountryInfo() { InternalID = 49, EnglishName = "Chad", ISO_3166_Name = @"CHAD", ISO_3166_Alpha2Code = "TD", ISO_3166_Alpha3Code = "TCD", PhoneCode = "+235", CurrencyCode = "XAF", NetEntCountryName = "CHAD" });
            countries.Add(new CountryInfo() { InternalID = 50, EnglishName = "Chile", ISO_3166_Name = @"CHILE", ISO_3166_Alpha2Code = "CL", ISO_3166_Alpha3Code = "CHL", PhoneCode = "+56", CurrencyCode = "CLP", NetEntCountryName = "CHILE" });
            countries.Add(new CountryInfo() { InternalID = 51, EnglishName = "China", ISO_3166_Name = @"CHINA", ISO_3166_Alpha2Code = "CN", ISO_3166_Alpha3Code = "CHN", PhoneCode = "+86", CurrencyCode = "CNY", NetEntCountryName = "CHINA" });
            countries.Add(new CountryInfo() { InternalID = 52, EnglishName = "Christmas Island", ISO_3166_Name = @"CHRISTMAS ISLAND", ISO_3166_Alpha2Code = "CX", ISO_3166_Alpha3Code = "   ", PhoneCode = "+53", CurrencyCode = "AUD", NetEntCountryName = "CHRISTMAS ISLAND" });
            countries.Add(new CountryInfo() { InternalID = 53, EnglishName = "Cocos (Keeling) Islands", ISO_3166_Name = @"COCOS (KEELING) ISLANDS", ISO_3166_Alpha2Code = "CC", ISO_3166_Alpha3Code = "   ", PhoneCode = "+61", CurrencyCode = "AUD", NetEntCountryName = "COCOS (KEELING) ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 54, EnglishName = "Colombia", ISO_3166_Name = @"COLOMBIA", ISO_3166_Alpha2Code = "CO", ISO_3166_Alpha3Code = "COL", PhoneCode = "+57", CurrencyCode = "COP", NetEntCountryName = "COLOMBIA" });
            countries.Add(new CountryInfo() { InternalID = 55, EnglishName = "Comoros", ISO_3166_Name = @"COMOROS", ISO_3166_Alpha2Code = "KM", ISO_3166_Alpha3Code = "COM", PhoneCode = "+269", CurrencyCode = "KMF", NetEntCountryName = "COMOROS" });
            countries.Add(new CountryInfo() { InternalID = 56, EnglishName = "Congo", ISO_3166_Name = @"CONGO", ISO_3166_Alpha2Code = "CG", ISO_3166_Alpha3Code = "COG", PhoneCode = "+242", CurrencyCode = "XAF", NetEntCountryName = "CONGO" });
            countries.Add(new CountryInfo() { InternalID = 0, EnglishName = "Congo, the Democratic Republic of the", ISO_3166_Name = @"CONGO, THE DEMOCRATIC REPUBLIC OF THE", ISO_3166_Alpha2Code = "CD", ISO_3166_Alpha3Code = "COD", PhoneCode = "", CurrencyCode = "CDF", NetEntCountryName = "" });
            countries.Add(new CountryInfo() { InternalID = 57, EnglishName = "Cook Islands", ISO_3166_Name = @"COOK ISLANDS", ISO_3166_Alpha2Code = "CK", ISO_3166_Alpha3Code = "COK", PhoneCode = "+682", CurrencyCode = "NZD", NetEntCountryName = "COOK ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 58, EnglishName = "Costa Rica", ISO_3166_Name = @"COSTA RICA", ISO_3166_Alpha2Code = "CR", ISO_3166_Alpha3Code = "CRI", PhoneCode = "+506", CurrencyCode = "CRC", NetEntCountryName = "COSTA RICA" });
            countries.Add(new CountryInfo() { InternalID = 59, EnglishName = "Cote D'Ivoire", ISO_3166_Name = @"COTE D'IVOIRE", ISO_3166_Alpha2Code = "CI", ISO_3166_Alpha3Code = "CIV", PhoneCode = "+225", CurrencyCode = "XOF", NetEntCountryName = "CÈTE D'IVOIRE" });
            countries.Add(new CountryInfo() { InternalID = 60, EnglishName = "Croatia", ISO_3166_Name = @"CROATIA", ISO_3166_Alpha2Code = "HR", ISO_3166_Alpha3Code = "HRV", PhoneCode = "+385", CurrencyCode = "HRK", NetEntCountryName = "CROATIA" });
            countries.Add(new CountryInfo() { InternalID = 61, EnglishName = "Cuba", ISO_3166_Name = @"CUBA", ISO_3166_Alpha2Code = "CU", ISO_3166_Alpha3Code = "CUB", PhoneCode = "+53", CurrencyCode = "CUP", NetEntCountryName = "CUBA" });
            countries.Add(new CountryInfo() { InternalID = 62, EnglishName = "Cyprus", ISO_3166_Name = @"CYPRUS", ISO_3166_Alpha2Code = "CY", ISO_3166_Alpha3Code = "CYP", PhoneCode = "+357", CurrencyCode = "CYP", NetEntCountryName = "CYPRUS" });
            countries.Add(new CountryInfo() { InternalID = 63, EnglishName = "Czech Republic", ISO_3166_Name = @"CZECH REPUBLIC", ISO_3166_Alpha2Code = "CZ", ISO_3166_Alpha3Code = "CZE", PhoneCode = "+420", CurrencyCode = "CSK", NetEntCountryName = "CZECH REPUBLIC" });
            countries.Add(new CountryInfo() { InternalID = 64, EnglishName = "Denmark", ISO_3166_Name = @"DENMARK", ISO_3166_Alpha2Code = "DK", ISO_3166_Alpha3Code = "DNK", PhoneCode = "+45", CurrencyCode = "DKK", NetEntCountryName = "DENMARK" });
            countries.Add(new CountryInfo() { InternalID = 65, EnglishName = "Djibouti", ISO_3166_Name = @"DJIBOUTI", ISO_3166_Alpha2Code = "DJ", ISO_3166_Alpha3Code = "DJI", PhoneCode = "+253", CurrencyCode = "DJF", NetEntCountryName = "DJIBOUTI" });
            countries.Add(new CountryInfo() { InternalID = 66, EnglishName = "Dominica", ISO_3166_Name = @"DOMINICA", ISO_3166_Alpha2Code = "DM", ISO_3166_Alpha3Code = "DMA", PhoneCode = "+1-767", CurrencyCode = "XCD", NetEntCountryName = "DOMINICA" });
            countries.Add(new CountryInfo() { InternalID = 67, EnglishName = "Dominican Republic", ISO_3166_Name = @"DOMINICAN REPUBLIC", ISO_3166_Alpha2Code = "DO", ISO_3166_Alpha3Code = "DOM", PhoneCode = "+1-829", CurrencyCode = "DOP", NetEntCountryName = "DOMINICAN REPUBLIC" });
            countries.Add(new CountryInfo() { InternalID = 69, EnglishName = "Ecuador", ISO_3166_Name = @"ECUADOR", ISO_3166_Alpha2Code = "EC", ISO_3166_Alpha3Code = "ECU", PhoneCode = "+593", CurrencyCode = "ECS", NetEntCountryName = "ECUADOR" });
            countries.Add(new CountryInfo() { InternalID = 70, EnglishName = "Egypt", ISO_3166_Name = @"EGYPT", ISO_3166_Alpha2Code = "EG", ISO_3166_Alpha3Code = "EGY", PhoneCode = "+20", CurrencyCode = "EGP", NetEntCountryName = "EGYPT" });
            countries.Add(new CountryInfo() { InternalID = 71, EnglishName = "El Salvador", ISO_3166_Name = @"EL SALVADOR", ISO_3166_Alpha2Code = "SV", ISO_3166_Alpha3Code = "SLV", PhoneCode = "+503", CurrencyCode = "SVC", NetEntCountryName = "EL SALVADOR" });
            countries.Add(new CountryInfo() { InternalID = 72, EnglishName = "Equatorial Guinea", ISO_3166_Name = @"EQUATORIAL GUINEA", ISO_3166_Alpha2Code = "GQ", ISO_3166_Alpha3Code = "GNQ", PhoneCode = "+240", CurrencyCode = "XAF", NetEntCountryName = "EQUATORIAL GUINEA" });
            countries.Add(new CountryInfo() { InternalID = 73, EnglishName = "Eritrea", ISO_3166_Name = @"ERITREA", ISO_3166_Alpha2Code = "ER", ISO_3166_Alpha3Code = "ERI", PhoneCode = "+291", CurrencyCode = "ETB", NetEntCountryName = "ERITREA" });
            countries.Add(new CountryInfo() { InternalID = 74, EnglishName = "Estonia", ISO_3166_Name = @"ESTONIA", ISO_3166_Alpha2Code = "EE", ISO_3166_Alpha3Code = "EST", PhoneCode = "+372", CurrencyCode = "EEK", NetEntCountryName = "ESTONIA" });
            countries.Add(new CountryInfo() { InternalID = 75, EnglishName = "Ethiopia", ISO_3166_Name = @"ETHIOPIA", ISO_3166_Alpha2Code = "ET", ISO_3166_Alpha3Code = "ETH", PhoneCode = "+251", CurrencyCode = "ETB", NetEntCountryName = "ETHIOPIA" });
            countries.Add(new CountryInfo() { InternalID = 76, EnglishName = "Falkland Islands (Malvinas)", ISO_3166_Name = @"FALKLAND ISLANDS (MALVINAS)", ISO_3166_Alpha2Code = "FK", ISO_3166_Alpha3Code = "FLK", PhoneCode = "+500", CurrencyCode = "FKP", NetEntCountryName = "FALKLAND ISLANDS (MALVINAS)" });
            countries.Add(new CountryInfo() { InternalID = 77, EnglishName = "Faroe Islands", ISO_3166_Name = @"FAROE ISLANDS", ISO_3166_Alpha2Code = "FO", ISO_3166_Alpha3Code = "FRO", PhoneCode = "+298", CurrencyCode = "DKK", NetEntCountryName = "FAROE ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 78, EnglishName = "Fiji", ISO_3166_Name = @"FIJI", ISO_3166_Alpha2Code = "FJ", ISO_3166_Alpha3Code = "FJI", PhoneCode = "+679", CurrencyCode = "FJD", NetEntCountryName = "FIJI" });
            countries.Add(new CountryInfo() { InternalID = 79, EnglishName = "Finland", ISO_3166_Name = @"FINLAND", ISO_3166_Alpha2Code = "FI", ISO_3166_Alpha3Code = "FIN", PhoneCode = "+358", CurrencyCode = "EUR", NetEntCountryName = "FINLAND" });
            countries.Add(new CountryInfo() { InternalID = 80, EnglishName = "France", ISO_3166_Name = @"FRANCE", ISO_3166_Alpha2Code = "FR", ISO_3166_Alpha3Code = "FRA", PhoneCode = "+33", CurrencyCode = "EUR", NetEntCountryName = "FRANCE" });
            countries.Add(new CountryInfo() { InternalID = 82, EnglishName = "French Guiana", ISO_3166_Name = @"FRENCH GUIANA", ISO_3166_Alpha2Code = "GF", ISO_3166_Alpha3Code = "GUF", PhoneCode = "+594", CurrencyCode = "EUR", NetEntCountryName = "FRENCH GUIANA" });
            countries.Add(new CountryInfo() { InternalID = 83, EnglishName = "French Polynesia", ISO_3166_Name = @"FRENCH POLYNESIA", ISO_3166_Alpha2Code = "PF", ISO_3166_Alpha3Code = "PYF", PhoneCode = "", CurrencyCode = "XPF", NetEntCountryName = "FRENCH POLYNESIA" });
            countries.Add(new CountryInfo() { InternalID = 84, EnglishName = "French Southern Territories", ISO_3166_Name = @"FRENCH SOUTHERN TERRITORIES", ISO_3166_Alpha2Code = "TF", ISO_3166_Alpha3Code = "   ", PhoneCode = "+596", CurrencyCode = "EUR", NetEntCountryName = "FRENCH SOUTHERN TERRITORIES" });
            countries.Add(new CountryInfo() { InternalID = 85, EnglishName = "Gabon", ISO_3166_Name = @"GABON", ISO_3166_Alpha2Code = "GA", ISO_3166_Alpha3Code = "GAB", PhoneCode = "+241", CurrencyCode = "XAF", NetEntCountryName = "GABON" });
            countries.Add(new CountryInfo() { InternalID = 86, EnglishName = "Gambia", ISO_3166_Name = @"GAMBIA", ISO_3166_Alpha2Code = "GM", ISO_3166_Alpha3Code = "GMB", PhoneCode = "+220", CurrencyCode = "GMD", NetEntCountryName = "GAMBIA" });
            countries.Add(new CountryInfo() { InternalID = 87, EnglishName = "Georgia", ISO_3166_Name = @"GEORGIA", ISO_3166_Alpha2Code = "GE", ISO_3166_Alpha3Code = "GEO", PhoneCode = "+995", CurrencyCode = "GEL", NetEntCountryName = "GEORGIA" });
            countries.Add(new CountryInfo() { InternalID = 88, EnglishName = "Germany", ISO_3166_Name = @"GERMANY", ISO_3166_Alpha2Code = "DE", ISO_3166_Alpha3Code = "DEU", PhoneCode = "+49", CurrencyCode = "EUR", NetEntCountryName = "GERMANY" });
            countries.Add(new CountryInfo() { InternalID = 89, EnglishName = "Ghana", ISO_3166_Name = @"GHANA", ISO_3166_Alpha2Code = "GH", ISO_3166_Alpha3Code = "GHA", PhoneCode = "+233", CurrencyCode = "GHC", NetEntCountryName = "GHANA" });
            countries.Add(new CountryInfo() { InternalID = 90, EnglishName = "Gibraltar", ISO_3166_Name = @"GIBRALTAR", ISO_3166_Alpha2Code = "GI", ISO_3166_Alpha3Code = "GIB", PhoneCode = "+350", CurrencyCode = "GIP", NetEntCountryName = "GIBRALTAR" });
            countries.Add(new CountryInfo() { InternalID = 91, EnglishName = "Greece", ISO_3166_Name = @"GREECE", ISO_3166_Alpha2Code = "GR", ISO_3166_Alpha3Code = "GRC", PhoneCode = "+30", CurrencyCode = "EUR", NetEntCountryName = "GREECE" });
            countries.Add(new CountryInfo() { InternalID = 92, EnglishName = "Greenland", ISO_3166_Name = @"GREENLAND", ISO_3166_Alpha2Code = "GL", ISO_3166_Alpha3Code = "GRL", PhoneCode = "+299", CurrencyCode = "DKK", NetEntCountryName = "GREENLAND" });
            countries.Add(new CountryInfo() { InternalID = 93, EnglishName = "Grenada", ISO_3166_Name = @"GRENADA", ISO_3166_Alpha2Code = "GD", ISO_3166_Alpha3Code = "GRD", PhoneCode = "+1-473", CurrencyCode = "XCD", NetEntCountryName = "GRENADA" });
            countries.Add(new CountryInfo() { InternalID = 94, EnglishName = "Guadeloupe", ISO_3166_Name = @"GUADELOUPE", ISO_3166_Alpha2Code = "GP", ISO_3166_Alpha3Code = "GLP", PhoneCode = "+590", CurrencyCode = "EUR", NetEntCountryName = "GUADELOUPE" });
            countries.Add(new CountryInfo() { InternalID = 95, EnglishName = "Guam", ISO_3166_Name = @"GUAM", ISO_3166_Alpha2Code = "GU", ISO_3166_Alpha3Code = "GUM", PhoneCode = "+1-671", CurrencyCode = "USD", NetEntCountryName = "GUAM" });
            countries.Add(new CountryInfo() { InternalID = 96, EnglishName = "Guatemala", ISO_3166_Name = @"GUATEMALA", ISO_3166_Alpha2Code = "GT", ISO_3166_Alpha3Code = "GTM", PhoneCode = "+502", CurrencyCode = "GTQ", NetEntCountryName = "GUATEMALA" });
            countries.Add(new CountryInfo() { InternalID = 97, EnglishName = "Guinea", ISO_3166_Name = @"GUINEA", ISO_3166_Alpha2Code = "GN", ISO_3166_Alpha3Code = "GIN", PhoneCode = "+224", CurrencyCode = "GNF", NetEntCountryName = "GUINEA" });
            countries.Add(new CountryInfo() { InternalID = 98, EnglishName = "Guinea-Bissau", ISO_3166_Name = @"GUINEA-BISSAU", ISO_3166_Alpha2Code = "GW", ISO_3166_Alpha3Code = "GNB", PhoneCode = "+245", CurrencyCode = "XOF", NetEntCountryName = "GUINEA-BISSAU" });
            countries.Add(new CountryInfo() { InternalID = 99, EnglishName = "Guyana", ISO_3166_Name = @"GUYANA", ISO_3166_Alpha2Code = "GY", ISO_3166_Alpha3Code = "GUY", PhoneCode = "+592", CurrencyCode = "GYD", NetEntCountryName = "GUYANA" });
            countries.Add(new CountryInfo() { InternalID = 100, EnglishName = "Haiti", ISO_3166_Name = @"HAITI", ISO_3166_Alpha2Code = "HT", ISO_3166_Alpha3Code = "HTI", PhoneCode = "+509", CurrencyCode = "HTG", NetEntCountryName = "HAITI" });
            countries.Add(new CountryInfo() { InternalID = 101, EnglishName = "Heard Island and Mcdonald Islands", ISO_3166_Name = @"HEARD ISLAND AND MCDONALD ISLANDS", ISO_3166_Alpha2Code = "HM", ISO_3166_Alpha3Code = "   ", PhoneCode = "", CurrencyCode = "AUD", NetEntCountryName = "HEARD ISLAND AND MCDONALD ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 236, EnglishName = "Holy See (Vatican City State)", ISO_3166_Name = @"HOLY SEE (VATICAN CITY STATE)", ISO_3166_Alpha2Code = "VA", ISO_3166_Alpha3Code = "VAT", PhoneCode = "+39", CurrencyCode = "EUR", NetEntCountryName = "HOLY SEE (VATICAN)" });
            countries.Add(new CountryInfo() { InternalID = 102, EnglishName = "Honduras", ISO_3166_Name = @"HONDURAS", ISO_3166_Alpha2Code = "HN", ISO_3166_Alpha3Code = "HND", PhoneCode = "+504", CurrencyCode = "HNL", NetEntCountryName = "HONDURAS" });
            countries.Add(new CountryInfo() { InternalID = 103, EnglishName = "Hong Kong", ISO_3166_Name = @"HONG KONG", ISO_3166_Alpha2Code = "HK", ISO_3166_Alpha3Code = "HKG", PhoneCode = "+852", CurrencyCode = "HKD", NetEntCountryName = "HONG KONG" });
            countries.Add(new CountryInfo() { InternalID = 104, EnglishName = "Hungary", ISO_3166_Name = @"HUNGARY", ISO_3166_Alpha2Code = "HU", ISO_3166_Alpha3Code = "HUN", PhoneCode = "+36", CurrencyCode = "HUF", NetEntCountryName = "HUNGARY" });
            countries.Add(new CountryInfo() { InternalID = 105, EnglishName = "Iceland", ISO_3166_Name = @"ICELAND", ISO_3166_Alpha2Code = "IS", ISO_3166_Alpha3Code = "ISL", PhoneCode = "+354", CurrencyCode = "ISK", NetEntCountryName = "ICELAND" });
            countries.Add(new CountryInfo() { InternalID = 106, EnglishName = "India", ISO_3166_Name = @"INDIA", ISO_3166_Alpha2Code = "IN", ISO_3166_Alpha3Code = "IND", PhoneCode = "+91", CurrencyCode = "INR", NetEntCountryName = "INDIA" });
            countries.Add(new CountryInfo() { InternalID = 107, EnglishName = "Indonesia", ISO_3166_Name = @"INDONESIA", ISO_3166_Alpha2Code = "ID", ISO_3166_Alpha3Code = "IDN", PhoneCode = "+62", CurrencyCode = "IDR", NetEntCountryName = "INDONESIA" });
            countries.Add(new CountryInfo() { InternalID = 108, EnglishName = "Iran, Islamic Republic of", ISO_3166_Name = @"IRAN, ISLAMIC REPUBLIC OF", ISO_3166_Alpha2Code = "IR", ISO_3166_Alpha3Code = "IRN", PhoneCode = "+98", CurrencyCode = "IRR", NetEntCountryName = "IRAN, ISLAMIC REPUBLIC OF" });
            countries.Add(new CountryInfo() { InternalID = 109, EnglishName = "Iraq", ISO_3166_Name = @"IRAQ", ISO_3166_Alpha2Code = "IQ", ISO_3166_Alpha3Code = "IRQ", PhoneCode = "+964", CurrencyCode = "IQD", NetEntCountryName = "IRAQ" });
            countries.Add(new CountryInfo() { InternalID = 110, EnglishName = "Ireland", ISO_3166_Name = @"IRELAND", ISO_3166_Alpha2Code = "IE", ISO_3166_Alpha3Code = "IRL", PhoneCode = "+353", CurrencyCode = "EUR", NetEntCountryName = "IRELAND" });
            countries.Add(new CountryInfo() { InternalID = 111, EnglishName = "Israel", ISO_3166_Name = @"ISRAEL", ISO_3166_Alpha2Code = "IL", ISO_3166_Alpha3Code = "ISR", PhoneCode = "+972", CurrencyCode = "ILS", NetEntCountryName = "ISRAEL" });
            countries.Add(new CountryInfo() { InternalID = 112, EnglishName = "Italy", ISO_3166_Name = @"ITALY", ISO_3166_Alpha2Code = "IT", ISO_3166_Alpha3Code = "ITA", PhoneCode = "+39", CurrencyCode = "EUR", NetEntCountryName = "ITALY" });
            countries.Add(new CountryInfo() { InternalID = 113, EnglishName = "Jamaica", ISO_3166_Name = @"JAMAICA", ISO_3166_Alpha2Code = "JM", ISO_3166_Alpha3Code = "JAM", PhoneCode = "+1-876", CurrencyCode = "JMD", NetEntCountryName = "JAMAICA" });
            countries.Add(new CountryInfo() { InternalID = 114, EnglishName = "Japan", ISO_3166_Name = @"JAPAN", ISO_3166_Alpha2Code = "JP", ISO_3166_Alpha3Code = "JPN", PhoneCode = "+81", CurrencyCode = "JPY", NetEntCountryName = "JAPAN" });
            countries.Add(new CountryInfo() { InternalID = 115, EnglishName = "Jordan", ISO_3166_Name = @"JORDAN", ISO_3166_Alpha2Code = "JO", ISO_3166_Alpha3Code = "JOR", PhoneCode = "+962", CurrencyCode = "JOD", NetEntCountryName = "JORDAN" });
            countries.Add(new CountryInfo() { InternalID = 116, EnglishName = "Kazakhstan", ISO_3166_Name = @"KAZAKHSTAN", ISO_3166_Alpha2Code = "KZ", ISO_3166_Alpha3Code = "KAZ", PhoneCode = "+7", CurrencyCode = "KZT", NetEntCountryName = "KAZAKSTAN" });
            countries.Add(new CountryInfo() { InternalID = 117, EnglishName = "Kenya", ISO_3166_Name = @"KENYA", ISO_3166_Alpha2Code = "KE", ISO_3166_Alpha3Code = "KEN", PhoneCode = "+254", CurrencyCode = "KES", NetEntCountryName = "KENYA" });
            countries.Add(new CountryInfo() { InternalID = 118, EnglishName = "Kiribati", ISO_3166_Name = @"KIRIBATI", ISO_3166_Alpha2Code = "KI", ISO_3166_Alpha3Code = "KIR", PhoneCode = "+686", CurrencyCode = "AUD", NetEntCountryName = "KIRIBATI" });
            countries.Add(new CountryInfo() { InternalID = 164, EnglishName = "Korea, Democratic People's Republic of", ISO_3166_Name = @"KOREA, DEMOCRATIC PEOPLE'S REPUBLIC OF", ISO_3166_Alpha2Code = "KP", ISO_3166_Alpha3Code = "PRK", PhoneCode = "+850", CurrencyCode = "KPW", NetEntCountryName = "KOREA, DEMOCRATIC PEOPLE'S REPUBLIC OF" });
            countries.Add(new CountryInfo() { InternalID = 202, EnglishName = "Korea, Republic of", ISO_3166_Name = @"KOREA, REPUBLIC OF", ISO_3166_Alpha2Code = "KR", ISO_3166_Alpha3Code = "KOR", PhoneCode = "", CurrencyCode = "KRW", NetEntCountryName = "KOREA, REPUBLIC OF" });
            countries.Add(new CountryInfo() { InternalID = 119, EnglishName = "Kuwait", ISO_3166_Name = @"KUWAIT", ISO_3166_Alpha2Code = "KW", ISO_3166_Alpha3Code = "KWT", PhoneCode = "+965", CurrencyCode = "KWD", NetEntCountryName = "KUWAIT" });
            countries.Add(new CountryInfo() { InternalID = 120, EnglishName = "Kyrgyzstan", ISO_3166_Name = @"KYRGYZSTAN", ISO_3166_Alpha2Code = "KG", ISO_3166_Alpha3Code = "KGZ", PhoneCode = "+996", CurrencyCode = "KGS", NetEntCountryName = "KYRGYZSTAN" });
            countries.Add(new CountryInfo() { InternalID = 121, EnglishName = "Lao People's Democratic Republic", ISO_3166_Name = @"LAO PEOPLE'S DEMOCRATIC REPUBLIC", ISO_3166_Alpha2Code = "LA", ISO_3166_Alpha3Code = "LAO", PhoneCode = "+856", CurrencyCode = "LAK", NetEntCountryName = "LAO PEOPLE'S DEMOCRATIC REPUBLIC" });
            countries.Add(new CountryInfo() { InternalID = 122, EnglishName = "Latvia", ISO_3166_Name = @"LATVIA", ISO_3166_Alpha2Code = "LV", ISO_3166_Alpha3Code = "LVA", PhoneCode = "+371", CurrencyCode = "LVL", NetEntCountryName = "LATVIA" });
            countries.Add(new CountryInfo() { InternalID = 123, EnglishName = "Lebanon", ISO_3166_Name = @"LEBANON", ISO_3166_Alpha2Code = "LB", ISO_3166_Alpha3Code = "LBN", PhoneCode = "+961", CurrencyCode = "LBP", NetEntCountryName = "LEBANON" });
            countries.Add(new CountryInfo() { InternalID = 124, EnglishName = "Lesotho", ISO_3166_Name = @"LESOTHO", ISO_3166_Alpha2Code = "LS", ISO_3166_Alpha3Code = "LSO", PhoneCode = "+266", CurrencyCode = "LSL", NetEntCountryName = "LESOTHO" });
            countries.Add(new CountryInfo() { InternalID = 125, EnglishName = "Liberia", ISO_3166_Name = @"LIBERIA", ISO_3166_Alpha2Code = "LR", ISO_3166_Alpha3Code = "LBR", PhoneCode = "+231", CurrencyCode = "LRD", NetEntCountryName = "LIBERIA" });
            countries.Add(new CountryInfo() { InternalID = 126, EnglishName = "Libyan Arab Jamahiriya", ISO_3166_Name = @"LIBYAN ARAB JAMAHIRIYA", ISO_3166_Alpha2Code = "LY", ISO_3166_Alpha3Code = "LBY", PhoneCode = "+218", CurrencyCode = "LYD", NetEntCountryName = "LIBYAN ARAB JAMAHIRIYA" });
            countries.Add(new CountryInfo() { InternalID = 127, EnglishName = "Liechtenstein", ISO_3166_Name = @"LIECHTENSTEIN", ISO_3166_Alpha2Code = "LI", ISO_3166_Alpha3Code = "LIE", PhoneCode = "+423", CurrencyCode = "CHF", NetEntCountryName = "LIECHTENSTEIN" });
            countries.Add(new CountryInfo() { InternalID = 128, EnglishName = "Lithuania", ISO_3166_Name = @"LITHUANIA", ISO_3166_Alpha2Code = "LT", ISO_3166_Alpha3Code = "LTU", PhoneCode = "+370", CurrencyCode = "LTL", NetEntCountryName = "LITHUANIA" });
            countries.Add(new CountryInfo() { InternalID = 129, EnglishName = "Luxembourg", ISO_3166_Name = @"LUXEMBOURG", ISO_3166_Alpha2Code = "LU", ISO_3166_Alpha3Code = "LUX", PhoneCode = "+352", CurrencyCode = "EUR", NetEntCountryName = "LUXEMBOURG" });
            countries.Add(new CountryInfo() { InternalID = 130, EnglishName = "Macao", ISO_3166_Name = @"MACAO", ISO_3166_Alpha2Code = "MO", ISO_3166_Alpha3Code = "MAC", PhoneCode = "+853", CurrencyCode = "MOP", NetEntCountryName = "MACAU" });
            countries.Add(new CountryInfo() { InternalID = 131, EnglishName = "Macedonia, the Former Yugoslav Republic of", ISO_3166_Name = @"MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF", ISO_3166_Alpha2Code = "MK", ISO_3166_Alpha3Code = "MKD", PhoneCode = "+389", CurrencyCode = "MKD", NetEntCountryName = "MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF" });
            countries.Add(new CountryInfo() { InternalID = 132, EnglishName = "Madagascar", ISO_3166_Name = @"MADAGASCAR", ISO_3166_Alpha2Code = "MG", ISO_3166_Alpha3Code = "MDG", PhoneCode = "+261", CurrencyCode = "MGF", NetEntCountryName = "MADAGASCAR" });
            countries.Add(new CountryInfo() { InternalID = 133, EnglishName = "Malawi", ISO_3166_Name = @"MALAWI", ISO_3166_Alpha2Code = "MW", ISO_3166_Alpha3Code = "MWI", PhoneCode = "+265", CurrencyCode = "MWK", NetEntCountryName = "MALAWI" });
            countries.Add(new CountryInfo() { InternalID = 134, EnglishName = "Malaysia", ISO_3166_Name = @"MALAYSIA", ISO_3166_Alpha2Code = "MY", ISO_3166_Alpha3Code = "MYS", PhoneCode = "+60", CurrencyCode = "MYR", NetEntCountryName = "MALAYSIA" });
            countries.Add(new CountryInfo() { InternalID = 135, EnglishName = "Maldives", ISO_3166_Name = @"MALDIVES", ISO_3166_Alpha2Code = "MV", ISO_3166_Alpha3Code = "MDV", PhoneCode = "+960", CurrencyCode = "MVR", NetEntCountryName = "MALDIVES" });
            countries.Add(new CountryInfo() { InternalID = 136, EnglishName = "Mali", ISO_3166_Name = @"MALI", ISO_3166_Alpha2Code = "ML", ISO_3166_Alpha3Code = "MLI", PhoneCode = "+223", CurrencyCode = "XOF", NetEntCountryName = "MALI" });
            countries.Add(new CountryInfo() { InternalID = 137, EnglishName = "Malta", ISO_3166_Name = @"MALTA", ISO_3166_Alpha2Code = "MT", ISO_3166_Alpha3Code = "MLT", PhoneCode = "+356", CurrencyCode = "MTL", NetEntCountryName = "MALTA" });
            countries.Add(new CountryInfo() { InternalID = 138, EnglishName = "Marshall Islands", ISO_3166_Name = @"MARSHALL ISLANDS", ISO_3166_Alpha2Code = "MH", ISO_3166_Alpha3Code = "MHL", PhoneCode = "+692", CurrencyCode = "USD", NetEntCountryName = "MARSHALL ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 139, EnglishName = "Martinique", ISO_3166_Name = @"MARTINIQUE", ISO_3166_Alpha2Code = "MQ", ISO_3166_Alpha3Code = "MTQ", PhoneCode = "", CurrencyCode = "EUR", NetEntCountryName = "MARTINIQUE" });
            countries.Add(new CountryInfo() { InternalID = 140, EnglishName = "Mauritania", ISO_3166_Name = @"MAURITANIA", ISO_3166_Alpha2Code = "MR", ISO_3166_Alpha3Code = "MRT", PhoneCode = "", CurrencyCode = "MRO", NetEntCountryName = "MAURITANIA" });
            countries.Add(new CountryInfo() { InternalID = 141, EnglishName = "Mauritius", ISO_3166_Name = @"MAURITIUS", ISO_3166_Alpha2Code = "MU", ISO_3166_Alpha3Code = "MUS", PhoneCode = "+230", CurrencyCode = "MUR", NetEntCountryName = "MAURITIUS" });
            countries.Add(new CountryInfo() { InternalID = 142, EnglishName = "Mayotte", ISO_3166_Name = @"MAYOTTE", ISO_3166_Alpha2Code = "YT", ISO_3166_Alpha3Code = "   ", PhoneCode = "+269", CurrencyCode = "EUR", NetEntCountryName = "MAYOTTE" });
            countries.Add(new CountryInfo() { InternalID = 143, EnglishName = "Mexico", ISO_3166_Name = @"MEXICO", ISO_3166_Alpha2Code = "MX", ISO_3166_Alpha3Code = "MEX", PhoneCode = "+52", CurrencyCode = "MXP", NetEntCountryName = "MEXICO" });
            countries.Add(new CountryInfo() { InternalID = 144, EnglishName = "Micronesia, Federated States of", ISO_3166_Name = @"MICRONESIA, FEDERATED STATES OF", ISO_3166_Alpha2Code = "FM", ISO_3166_Alpha3Code = "FSM", PhoneCode = "+691", CurrencyCode = "USD", NetEntCountryName = "MICRONESIA, FEDERATED STATES OF" });
            countries.Add(new CountryInfo() { InternalID = 145, EnglishName = "Moldova, Republic of", ISO_3166_Name = @"MOLDOVA, REPUBLIC OF", ISO_3166_Alpha2Code = "MD", ISO_3166_Alpha3Code = "MDA", PhoneCode = "+373", CurrencyCode = "MDL", NetEntCountryName = "MOLDOVA, REPUBLIC OF" });
            countries.Add(new CountryInfo() { InternalID = 146, EnglishName = "Monaco", ISO_3166_Name = @"MONACO", ISO_3166_Alpha2Code = "MC", ISO_3166_Alpha3Code = "MCO", PhoneCode = "+377", CurrencyCode = "EUR", NetEntCountryName = "MONACO" });
            countries.Add(new CountryInfo() { InternalID = 147, EnglishName = "Mongolia", ISO_3166_Name = @"MONGOLIA", ISO_3166_Alpha2Code = "MN", ISO_3166_Alpha3Code = "MNG", PhoneCode = "+976", CurrencyCode = "MNT", NetEntCountryName = "MONGOLIA" });
            countries.Add(new CountryInfo() { InternalID = 148, EnglishName = "Montserrat", ISO_3166_Name = @"MONTSERRAT", ISO_3166_Alpha2Code = "MS", ISO_3166_Alpha3Code = "MSR", PhoneCode = "+1-664", CurrencyCode = "XCD", NetEntCountryName = "MONTSERRAT" });
            countries.Add(new CountryInfo() { InternalID = 149, EnglishName = "Morocco", ISO_3166_Name = @"MOROCCO", ISO_3166_Alpha2Code = "MA", ISO_3166_Alpha3Code = "MAR", PhoneCode = "+212", CurrencyCode = "MAD", NetEntCountryName = "MOROCCO" });
            countries.Add(new CountryInfo() { InternalID = 150, EnglishName = "Mozambique", ISO_3166_Name = @"MOZAMBIQUE", ISO_3166_Alpha2Code = "MZ", ISO_3166_Alpha3Code = "MOZ", PhoneCode = "+258", CurrencyCode = "MZM", NetEntCountryName = "MOZAMBIQUE" });
            countries.Add(new CountryInfo() { InternalID = 151, EnglishName = "Myanmar", ISO_3166_Name = @"MYANMAR", ISO_3166_Alpha2Code = "MM", ISO_3166_Alpha3Code = "MMR", PhoneCode = "+95", CurrencyCode = "MMK", NetEntCountryName = "MYANMAR" });
            countries.Add(new CountryInfo() { InternalID = 152, EnglishName = "Namibia", ISO_3166_Name = @"NAMIBIA", ISO_3166_Alpha2Code = "NA", ISO_3166_Alpha3Code = "NAM", PhoneCode = "+264", CurrencyCode = "NAD", NetEntCountryName = "NAMIBIA" });
            countries.Add(new CountryInfo() { InternalID = 153, EnglishName = "Nauru", ISO_3166_Name = @"NAURU", ISO_3166_Alpha2Code = "NR", ISO_3166_Alpha3Code = "NRU", PhoneCode = "+674", CurrencyCode = "AUD", NetEntCountryName = "NAURU" });
            countries.Add(new CountryInfo() { InternalID = 154, EnglishName = "Nepal", ISO_3166_Name = @"NEPAL", ISO_3166_Alpha2Code = "NP", ISO_3166_Alpha3Code = "NPL", PhoneCode = "+977", CurrencyCode = "NPR", NetEntCountryName = "NEPAL" });
            countries.Add(new CountryInfo() { InternalID = 155, EnglishName = "Netherlands", ISO_3166_Name = @"NETHERLANDS", ISO_3166_Alpha2Code = "NL", ISO_3166_Alpha3Code = "NLD", PhoneCode = "+31", CurrencyCode = "EUR", NetEntCountryName = "THE NETHERLANDS" });
            countries.Add(new CountryInfo() { InternalID = 156, EnglishName = "Netherlands Antilles", ISO_3166_Name = @"NETHERLANDS ANTILLES", ISO_3166_Alpha2Code = "AN", ISO_3166_Alpha3Code = "ANT", PhoneCode = "+599", CurrencyCode = "ANG", NetEntCountryName = "NETHERLANDS ANTILLES" });
            countries.Add(new CountryInfo() { InternalID = 157, EnglishName = "New Caledonia", ISO_3166_Name = @"NEW CALEDONIA", ISO_3166_Alpha2Code = "NC", ISO_3166_Alpha3Code = "NCL", PhoneCode = "+687", CurrencyCode = "XPF", NetEntCountryName = "NEW CALEDONIA" });
            countries.Add(new CountryInfo() { InternalID = 158, EnglishName = "New Zealand", ISO_3166_Name = @"NEW ZEALAND", ISO_3166_Alpha2Code = "NZ", ISO_3166_Alpha3Code = "NZL", PhoneCode = "+64", CurrencyCode = "NZD", NetEntCountryName = "NEW ZEALAND" });
            countries.Add(new CountryInfo() { InternalID = 159, EnglishName = "Nicaragua", ISO_3166_Name = @"NICARAGUA", ISO_3166_Alpha2Code = "NI", ISO_3166_Alpha3Code = "NIC", PhoneCode = "+505", CurrencyCode = "NIO", NetEntCountryName = "NICARAGUA" });
            countries.Add(new CountryInfo() { InternalID = 160, EnglishName = "Niger", ISO_3166_Name = @"NIGER", ISO_3166_Alpha2Code = "NE", ISO_3166_Alpha3Code = "NER", PhoneCode = "+227", CurrencyCode = "XOF", NetEntCountryName = "NIGER" });
            countries.Add(new CountryInfo() { InternalID = 161, EnglishName = "Nigeria", ISO_3166_Name = @"NIGERIA", ISO_3166_Alpha2Code = "NG", ISO_3166_Alpha3Code = "NGA", PhoneCode = "+234", CurrencyCode = "NGN", NetEntCountryName = "NIGERIA" });
            countries.Add(new CountryInfo() { InternalID = 162, EnglishName = "Niue", ISO_3166_Name = @"NIUE", ISO_3166_Alpha2Code = "NU", ISO_3166_Alpha3Code = "NIU", PhoneCode = "+683", CurrencyCode = "NZD", NetEntCountryName = "NIUE" });
            countries.Add(new CountryInfo() { InternalID = 163, EnglishName = "Norfolk Island", ISO_3166_Name = @"NORFOLK ISLAND", ISO_3166_Alpha2Code = "NF", ISO_3166_Alpha3Code = "NFK", PhoneCode = "+672", CurrencyCode = "AUD", NetEntCountryName = "NORFOLK ISLAND" });
            countries.Add(new CountryInfo() { InternalID = 165, EnglishName = "Northern Mariana Islands", ISO_3166_Name = @"NORTHERN MARIANA ISLANDS", ISO_3166_Alpha2Code = "MP", ISO_3166_Alpha3Code = "MNP", PhoneCode = "+1-670", CurrencyCode = "USD", NetEntCountryName = "NORTHERN MARIANA ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 166, EnglishName = "Norway", ISO_3166_Name = @"NORWAY", ISO_3166_Alpha2Code = "NO", ISO_3166_Alpha3Code = "NOR", PhoneCode = "+47", CurrencyCode = "NOK", NetEntCountryName = "NORWAY" });
            countries.Add(new CountryInfo() { InternalID = 167, EnglishName = "Oman", ISO_3166_Name = @"OMAN", ISO_3166_Alpha2Code = "OM", ISO_3166_Alpha3Code = "OMN", PhoneCode = "+968", CurrencyCode = "OMR", NetEntCountryName = "OMAN" });
            countries.Add(new CountryInfo() { InternalID = 169, EnglishName = "Pakistan", ISO_3166_Name = @"PAKISTAN", ISO_3166_Alpha2Code = "PK", ISO_3166_Alpha3Code = "PAK", PhoneCode = "+92", CurrencyCode = "PKR", NetEntCountryName = "PAKISTAN" });
            countries.Add(new CountryInfo() { InternalID = 170, EnglishName = "Palau", ISO_3166_Name = @"PALAU", ISO_3166_Alpha2Code = "PW", ISO_3166_Alpha3Code = "PLW", PhoneCode = "+680", CurrencyCode = "USD", NetEntCountryName = "PALAU" });
            countries.Add(new CountryInfo() { InternalID = 0, EnglishName = "Palestinian Territory, Occupied", ISO_3166_Name = @"PALESTINIAN TERRITORY, OCCUPIED", ISO_3166_Alpha2Code = "PS", ISO_3166_Alpha3Code = "   ", PhoneCode = "", CurrencyCode = "", NetEntCountryName = "" });
            countries.Add(new CountryInfo() { InternalID = 171, EnglishName = "Panama", ISO_3166_Name = @"PANAMA", ISO_3166_Alpha2Code = "PA", ISO_3166_Alpha3Code = "PAN", PhoneCode = "+507", CurrencyCode = "PAB", NetEntCountryName = "PANAMA" });
            countries.Add(new CountryInfo() { InternalID = 172, EnglishName = "Papua New Guinea", ISO_3166_Name = @"PAPUA NEW GUINEA", ISO_3166_Alpha2Code = "PG", ISO_3166_Alpha3Code = "PNG", PhoneCode = "+675", CurrencyCode = "PGK", NetEntCountryName = "PAPUA NEW GUINEA" });
            countries.Add(new CountryInfo() { InternalID = 173, EnglishName = "Paraguay", ISO_3166_Name = @"PARAGUAY", ISO_3166_Alpha2Code = "PY", ISO_3166_Alpha3Code = "PRY", PhoneCode = "+595", CurrencyCode = "PYG", NetEntCountryName = "PARAGUAY" });
            countries.Add(new CountryInfo() { InternalID = 174, EnglishName = "Peru", ISO_3166_Name = @"PERU", ISO_3166_Alpha2Code = "PE", ISO_3166_Alpha3Code = "PER", PhoneCode = "+51", CurrencyCode = "PEN", NetEntCountryName = "PERU" });
            countries.Add(new CountryInfo() { InternalID = 175, EnglishName = "Philippines", ISO_3166_Name = @"PHILIPPINES", ISO_3166_Alpha2Code = "PH", ISO_3166_Alpha3Code = "PHL", PhoneCode = "+63", CurrencyCode = "PHP", NetEntCountryName = "THE PHILIPPINES" });
            countries.Add(new CountryInfo() { InternalID = 176, EnglishName = "Pitcairn", ISO_3166_Name = @"PITCAIRN", ISO_3166_Alpha2Code = "PN", ISO_3166_Alpha3Code = "PCN", PhoneCode = "+872", CurrencyCode = "NZD", NetEntCountryName = "PITCAIRN" });
            countries.Add(new CountryInfo() { InternalID = 177, EnglishName = "Poland", ISO_3166_Name = @"POLAND", ISO_3166_Alpha2Code = "PL", ISO_3166_Alpha3Code = "POL", PhoneCode = "+48", CurrencyCode = "PLZ", NetEntCountryName = "POLAND" });
            countries.Add(new CountryInfo() { InternalID = 178, EnglishName = "Portugal", ISO_3166_Name = @"PORTUGAL", ISO_3166_Alpha2Code = "PT", ISO_3166_Alpha3Code = "PRT", PhoneCode = "+351", CurrencyCode = "EUR", NetEntCountryName = "PORTUGAL" });
            countries.Add(new CountryInfo() { InternalID = 179, EnglishName = "Puerto Rico", ISO_3166_Name = @"PUERTO RICO", ISO_3166_Alpha2Code = "PR", ISO_3166_Alpha3Code = "PRI", PhoneCode = "+1-787", CurrencyCode = "USD", NetEntCountryName = "PUERTO RICO" });
            countries.Add(new CountryInfo() { InternalID = 180, EnglishName = "Qatar", ISO_3166_Name = @"QATAR", ISO_3166_Alpha2Code = "QA", ISO_3166_Alpha3Code = "QAT", PhoneCode = "+974", CurrencyCode = "QAR", NetEntCountryName = "QATAR" });
            countries.Add(new CountryInfo() { InternalID = 181, EnglishName = "Reunion", ISO_3166_Name = @"REUNION", ISO_3166_Alpha2Code = "RE", ISO_3166_Alpha3Code = "REU", PhoneCode = "+262", CurrencyCode = "EUR", NetEntCountryName = "R+UNION" });
            countries.Add(new CountryInfo() { InternalID = 182, EnglishName = "Romania", ISO_3166_Name = @"ROMANIA", ISO_3166_Alpha2Code = "RO", ISO_3166_Alpha3Code = "ROM", PhoneCode = "+40", CurrencyCode = "ROL", NetEntCountryName = "ROMANIA" });
            countries.Add(new CountryInfo() { InternalID = 183, EnglishName = "Russian Federation", ISO_3166_Name = @"RUSSIAN FEDERATION", ISO_3166_Alpha2Code = "RU", ISO_3166_Alpha3Code = "RUS", PhoneCode = "+7", CurrencyCode = "RUR", NetEntCountryName = "RUSSIAN FEDERATION" });
            countries.Add(new CountryInfo() { InternalID = 184, EnglishName = "Rwanda", ISO_3166_Name = @"RWANDA", ISO_3166_Alpha2Code = "RW", ISO_3166_Alpha3Code = "RWA", PhoneCode = "+250", CurrencyCode = "RWF", NetEntCountryName = "RWANDA" });
            countries.Add(new CountryInfo() { InternalID = 205, EnglishName = "Saint Helena", ISO_3166_Name = @"SAINT HELENA", ISO_3166_Alpha2Code = "SH", ISO_3166_Alpha3Code = "SHN", PhoneCode = "", CurrencyCode = "", NetEntCountryName = "SAINT HELENA" });
            countries.Add(new CountryInfo() { InternalID = 185, EnglishName = "Saint Kitts and Nevis", ISO_3166_Name = @"SAINT KITTS AND NEVIS", ISO_3166_Alpha2Code = "KN", ISO_3166_Alpha3Code = "KNA", PhoneCode = "+1-869", CurrencyCode = "XCD", NetEntCountryName = "SAINT KITTS AND NEVIS" });
            countries.Add(new CountryInfo() { InternalID = 186, EnglishName = "Saint Lucia", ISO_3166_Name = @"SAINT LUCIA", ISO_3166_Alpha2Code = "LC", ISO_3166_Alpha3Code = "LCA", PhoneCode = "+1-758", CurrencyCode = "XCD", NetEntCountryName = "SAINT LUCIA" });
            countries.Add(new CountryInfo() { InternalID = 206, EnglishName = "Saint Pierre and Miquelon", ISO_3166_Name = @"SAINT PIERRE AND MIQUELON", ISO_3166_Alpha2Code = "PM", ISO_3166_Alpha3Code = "SPM", PhoneCode = "", CurrencyCode = "", NetEntCountryName = "SAINT PIERRE AND MIQUELON" });
            countries.Add(new CountryInfo() { InternalID = 187, EnglishName = "Saint Vincent and the Grenadines", ISO_3166_Name = @"SAINT VINCENT AND THE GRENADINES", ISO_3166_Alpha2Code = "VC", ISO_3166_Alpha3Code = "VCT", PhoneCode = "+1-784", CurrencyCode = "XCD", NetEntCountryName = "SAINT VINCENT AND THE GRENADINES" });
            countries.Add(new CountryInfo() { InternalID = 188, EnglishName = "Samoa", ISO_3166_Name = @"SAMOA", ISO_3166_Alpha2Code = "WS", ISO_3166_Alpha3Code = "WSM", PhoneCode = "+684", CurrencyCode = "EUR", NetEntCountryName = "SAMOA" });
            countries.Add(new CountryInfo() { InternalID = 189, EnglishName = "San Marino", ISO_3166_Name = @"SAN MARINO", ISO_3166_Alpha2Code = "SM", ISO_3166_Alpha3Code = "SMR", PhoneCode = "+378", CurrencyCode = "EUR", NetEntCountryName = "SAN MARINO" });
            countries.Add(new CountryInfo() { InternalID = 190, EnglishName = "Sao Tome and Principe", ISO_3166_Name = @"SAO TOME AND PRINCIPE", ISO_3166_Alpha2Code = "ST", ISO_3166_Alpha3Code = "STP", PhoneCode = "", CurrencyCode = "STD", NetEntCountryName = "SAO TOME AND PRINCIPE" });
            countries.Add(new CountryInfo() { InternalID = 191, EnglishName = "Saudi Arabia", ISO_3166_Name = @"SAUDI ARABIA", ISO_3166_Alpha2Code = "SA", ISO_3166_Alpha3Code = "SAU", PhoneCode = "+966", CurrencyCode = "SAR", NetEntCountryName = "SAUDI ARABIA" });
            countries.Add(new CountryInfo() { InternalID = 192, EnglishName = "Senegal", ISO_3166_Name = @"SENEGAL", ISO_3166_Alpha2Code = "SN", ISO_3166_Alpha3Code = "SEN", PhoneCode = "+221", CurrencyCode = "XOF", NetEntCountryName = "SENEGAL" });
            countries.Add(new CountryInfo() { InternalID = 0, EnglishName = "Serbia and Montenegro", ISO_3166_Name = @"SERBIA AND MONTENEGRO", ISO_3166_Alpha2Code = "CS", ISO_3166_Alpha3Code = "   ", PhoneCode = "", CurrencyCode = "", NetEntCountryName = "" });
            countries.Add(new CountryInfo() { InternalID = 193, EnglishName = "Seychelles", ISO_3166_Name = @"SEYCHELLES", ISO_3166_Alpha2Code = "SC", ISO_3166_Alpha3Code = "SYC", PhoneCode = "+248", CurrencyCode = "SCR", NetEntCountryName = "SEYCHELLES" });
            countries.Add(new CountryInfo() { InternalID = 194, EnglishName = "Sierra Leone", ISO_3166_Name = @"SIERRA LEONE", ISO_3166_Alpha2Code = "SL", ISO_3166_Alpha3Code = "SLE", PhoneCode = "+232", CurrencyCode = "SLL", NetEntCountryName = "SIERRA LEONE" });
            countries.Add(new CountryInfo() { InternalID = 195, EnglishName = "Singapore", ISO_3166_Name = @"SINGAPORE", ISO_3166_Alpha2Code = "SG", ISO_3166_Alpha3Code = "SGP", PhoneCode = "+65", CurrencyCode = "SGD", NetEntCountryName = "SINGAPORE" });
            countries.Add(new CountryInfo() { InternalID = 196, EnglishName = "Slovakia", ISO_3166_Name = @"SLOVAKIA", ISO_3166_Alpha2Code = "SK", ISO_3166_Alpha3Code = "SVK", PhoneCode = "+421", CurrencyCode = "SKK", NetEntCountryName = "SLOVAKIA" });
            countries.Add(new CountryInfo() { InternalID = 197, EnglishName = "Slovenia", ISO_3166_Name = @"SLOVENIA", ISO_3166_Alpha2Code = "SI", ISO_3166_Alpha3Code = "SVN", PhoneCode = "+386", CurrencyCode = "EUR", NetEntCountryName = "SLOVENIA" });
            countries.Add(new CountryInfo() { InternalID = 198, EnglishName = "Solomon Islands", ISO_3166_Name = @"SOLOMON ISLANDS", ISO_3166_Alpha2Code = "SB", ISO_3166_Alpha3Code = "SLB", PhoneCode = "+677", CurrencyCode = "SBD", NetEntCountryName = "SOLOMON ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 199, EnglishName = "Somalia", ISO_3166_Name = @"SOMALIA", ISO_3166_Alpha2Code = "SO", ISO_3166_Alpha3Code = "SOM", PhoneCode = "+252", CurrencyCode = "SOS", NetEntCountryName = "SOMALIA" });
            countries.Add(new CountryInfo() { InternalID = 200, EnglishName = "South Africa", ISO_3166_Name = @"SOUTH AFRICA", ISO_3166_Alpha2Code = "ZA", ISO_3166_Alpha3Code = "ZAF", PhoneCode = "+27", CurrencyCode = "ZAR", NetEntCountryName = "SOUTH AFRICA" });
            countries.Add(new CountryInfo() { InternalID = 201, EnglishName = "South Georgia and the South Sandwich Islands", ISO_3166_Name = @"SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS", ISO_3166_Alpha2Code = "GS", ISO_3166_Alpha3Code = "   ", PhoneCode = "+82", CurrencyCode = "GBP", NetEntCountryName = "S. GEORGIA & S. SANDW. IS." });
            countries.Add(new CountryInfo() { InternalID = 203, EnglishName = "Spain", ISO_3166_Name = @"SPAIN", ISO_3166_Alpha2Code = "ES", ISO_3166_Alpha3Code = "ESP", PhoneCode = "+34", CurrencyCode = "EUR", NetEntCountryName = "SPAIN" });
            countries.Add(new CountryInfo() { InternalID = 204, EnglishName = "Sri Lanka", ISO_3166_Name = @"SRI LANKA", ISO_3166_Alpha2Code = "LK", ISO_3166_Alpha3Code = "LKA", PhoneCode = "+94", CurrencyCode = "LKR", NetEntCountryName = "SRI LANKA" });
            countries.Add(new CountryInfo() { InternalID = 207, EnglishName = "Sudan", ISO_3166_Name = @"SUDAN", ISO_3166_Alpha2Code = "SD", ISO_3166_Alpha3Code = "SDN", PhoneCode = "+249", CurrencyCode = "SDD", NetEntCountryName = "SUDAN" });
            countries.Add(new CountryInfo() { InternalID = 208, EnglishName = "Suriname", ISO_3166_Name = @"SURINAME", ISO_3166_Alpha2Code = "SR", ISO_3166_Alpha3Code = "SUR", PhoneCode = "+597", CurrencyCode = "SRG", NetEntCountryName = "SURINAME" });
            countries.Add(new CountryInfo() { InternalID = 209, EnglishName = "Svalbard and Jan Mayen", ISO_3166_Name = @"SVALBARD AND JAN MAYEN", ISO_3166_Alpha2Code = "SJ", ISO_3166_Alpha3Code = "SJM", PhoneCode = "+47", CurrencyCode = "NOK", NetEntCountryName = "SVALBARD AND JAN MAYEN" });
            countries.Add(new CountryInfo() { InternalID = 210, EnglishName = "Swaziland", ISO_3166_Name = @"SWAZILAND", ISO_3166_Alpha2Code = "SZ", ISO_3166_Alpha3Code = "SWZ", PhoneCode = "+268", CurrencyCode = "SZL", NetEntCountryName = "SWAZILAND" });
            countries.Add(new CountryInfo() { InternalID = 211, EnglishName = "Sweden", ISO_3166_Name = @"SWEDEN", ISO_3166_Alpha2Code = "SE", ISO_3166_Alpha3Code = "SWE", PhoneCode = "+46", CurrencyCode = "SEK", NetEntCountryName = "SWEDEN" });
            countries.Add(new CountryInfo() { InternalID = 212, EnglishName = "Switzerland", ISO_3166_Name = @"SWITZERLAND", ISO_3166_Alpha2Code = "CH", ISO_3166_Alpha3Code = "CHE", PhoneCode = "+41", CurrencyCode = "CHF", NetEntCountryName = "SWITZERLAND" });
            countries.Add(new CountryInfo() { InternalID = 213, EnglishName = "Syrian Arab Republic", ISO_3166_Name = @"SYRIAN ARAB REPUBLIC", ISO_3166_Alpha2Code = "SY", ISO_3166_Alpha3Code = "SYR", PhoneCode = "+963", CurrencyCode = "SYP", NetEntCountryName = "SYRIAN ARAB REPUBLIC" });
            countries.Add(new CountryInfo() { InternalID = 214, EnglishName = "Taiwan, Province of China", ISO_3166_Name = @"TAIWAN, PROVINCE OF CHINA", ISO_3166_Alpha2Code = "TW", ISO_3166_Alpha3Code = "TWN", PhoneCode = "+886", CurrencyCode = "TWD", NetEntCountryName = "TAIWAN" });
            countries.Add(new CountryInfo() { InternalID = 215, EnglishName = "Tajikistan", ISO_3166_Name = @"TAJIKISTAN", ISO_3166_Alpha2Code = "TJ", ISO_3166_Alpha3Code = "TJK", PhoneCode = "+992", CurrencyCode = "TJR", NetEntCountryName = "TAJIKISTAN" });
            countries.Add(new CountryInfo() { InternalID = 216, EnglishName = "Tanzania, United Republic of", ISO_3166_Name = @"TANZANIA, UNITED REPUBLIC OF", ISO_3166_Alpha2Code = "TZ", ISO_3166_Alpha3Code = "TZA", PhoneCode = "+255", CurrencyCode = "TZS", NetEntCountryName = "TANZANIA, UNITED REPUBLIC OF" });
            countries.Add(new CountryInfo() { InternalID = 217, EnglishName = "Thailand", ISO_3166_Name = @"THAILAND", ISO_3166_Alpha2Code = "TH", ISO_3166_Alpha3Code = "THA", PhoneCode = "+66", CurrencyCode = "THB", NetEntCountryName = "THAILAND" });
            countries.Add(new CountryInfo() { InternalID = 0, EnglishName = "Timor-Leste", ISO_3166_Name = @"TIMOR-LESTE", ISO_3166_Alpha2Code = "TL", ISO_3166_Alpha3Code = "   ", PhoneCode = "", CurrencyCode = "", NetEntCountryName = "" });
            countries.Add(new CountryInfo() { InternalID = 218, EnglishName = "Togo", ISO_3166_Name = @"TOGO", ISO_3166_Alpha2Code = "TG", ISO_3166_Alpha3Code = "TGO", PhoneCode = "+228", CurrencyCode = "XOF", NetEntCountryName = "TOGO" });
            countries.Add(new CountryInfo() { InternalID = 219, EnglishName = "Tokelau", ISO_3166_Name = @"TOKELAU", ISO_3166_Alpha2Code = "TK", ISO_3166_Alpha3Code = "TKL", PhoneCode = "+690", CurrencyCode = "NZD", NetEntCountryName = "TOKELAU" });
            countries.Add(new CountryInfo() { InternalID = 220, EnglishName = "Tonga", ISO_3166_Name = @"TONGA", ISO_3166_Alpha2Code = "TO", ISO_3166_Alpha3Code = "TON", PhoneCode = "+676", CurrencyCode = "TOP", NetEntCountryName = "TONGA" });
            countries.Add(new CountryInfo() { InternalID = 221, EnglishName = "Trinidad and Tobago", ISO_3166_Name = @"TRINIDAD AND TOBAGO", ISO_3166_Alpha2Code = "TT", ISO_3166_Alpha3Code = "TTO", PhoneCode = "+1-868", CurrencyCode = "TTD", NetEntCountryName = "TRINIDAD AND TOBAGO" });
            countries.Add(new CountryInfo() { InternalID = 222, EnglishName = "Tunisia", ISO_3166_Name = @"TUNISIA", ISO_3166_Alpha2Code = "TN", ISO_3166_Alpha3Code = "TUN", PhoneCode = "+216", CurrencyCode = "TND", NetEntCountryName = "TUNISIA" });
            countries.Add(new CountryInfo() { InternalID = 223, EnglishName = "Turkey", ISO_3166_Name = @"TURKEY", ISO_3166_Alpha2Code = "TR", ISO_3166_Alpha3Code = "TUR", PhoneCode = "+90", CurrencyCode = "TRL", NetEntCountryName = "TURKEY" });
            countries.Add(new CountryInfo() { InternalID = 224, EnglishName = "Turkmenistan", ISO_3166_Name = @"TURKMENISTAN", ISO_3166_Alpha2Code = "TM", ISO_3166_Alpha3Code = "TKM", PhoneCode = "+993", CurrencyCode = "TMM", NetEntCountryName = "TURKMENISTAN" });
            countries.Add(new CountryInfo() { InternalID = 225, EnglishName = "Turks and Caicos Islands", ISO_3166_Name = @"TURKS AND CAICOS ISLANDS", ISO_3166_Alpha2Code = "TC", ISO_3166_Alpha3Code = "TCA", PhoneCode = "+1-649", CurrencyCode = "USD", NetEntCountryName = "TURKS AND CAICOS ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 226, EnglishName = "Tuvalu", ISO_3166_Name = @"TUVALU", ISO_3166_Alpha2Code = "TV", ISO_3166_Alpha3Code = "TUV", PhoneCode = "+688", CurrencyCode = "AUD", NetEntCountryName = "TUVALU" });
            countries.Add(new CountryInfo() { InternalID = 227, EnglishName = "Uganda", ISO_3166_Name = @"UGANDA", ISO_3166_Alpha2Code = "UG", ISO_3166_Alpha3Code = "UGA", PhoneCode = "+256", CurrencyCode = "UGX", NetEntCountryName = "UGANDA" });
            countries.Add(new CountryInfo() { InternalID = 228, EnglishName = "Ukraine", ISO_3166_Name = @"UKRAINE", ISO_3166_Alpha2Code = "UA", ISO_3166_Alpha3Code = "UKR", PhoneCode = "+380", CurrencyCode = "UAH", NetEntCountryName = "UKRAINE" });
            countries.Add(new CountryInfo() { InternalID = 229, EnglishName = "United Arab Emirates", ISO_3166_Name = @"UNITED ARAB EMIRATES", ISO_3166_Alpha2Code = "AE", ISO_3166_Alpha3Code = "ARE", PhoneCode = "+971", CurrencyCode = "AED", NetEntCountryName = "UNITED ARAB EMIRATES" });
            countries.Add(new CountryInfo() { InternalID = 230, EnglishName = "United Kingdom", ISO_3166_Name = @"UNITED KINGDOM", ISO_3166_Alpha2Code = "GB", ISO_3166_Alpha3Code = "GBR", PhoneCode = "+44", CurrencyCode = "GBP", NetEntCountryName = "UNITED KINGDOM" });
            countries.Add(new CountryInfo() { InternalID = 231, EnglishName = "United States", ISO_3166_Name = @"UNITED STATES", ISO_3166_Alpha2Code = "US", ISO_3166_Alpha3Code = "USA", PhoneCode = "+1", CurrencyCode = "USD", NetEntCountryName = "U S A" });
            countries.Add(new CountryInfo() { InternalID = 232, EnglishName = "United States Minor Outlying Islands", ISO_3166_Name = @"UNITED STATES MINOR OUTLYING ISLANDS", ISO_3166_Alpha2Code = "UM", ISO_3166_Alpha3Code = "   ", PhoneCode = "", CurrencyCode = "USD", NetEntCountryName = "UNITED STATES MINOR OUTLYING ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 233, EnglishName = "Uruguay", ISO_3166_Name = @"URUGUAY", ISO_3166_Alpha2Code = "UY", ISO_3166_Alpha3Code = "URY", PhoneCode = "+598", CurrencyCode = "UYU", NetEntCountryName = "URUGUAY" });
            countries.Add(new CountryInfo() { InternalID = 234, EnglishName = "Uzbekistan", ISO_3166_Name = @"UZBEKISTAN", ISO_3166_Alpha2Code = "UZ", ISO_3166_Alpha3Code = "UZB", PhoneCode = "+998", CurrencyCode = "UZS", NetEntCountryName = "UZBEKISTAN" });
            countries.Add(new CountryInfo() { InternalID = 235, EnglishName = "Vanuatu", ISO_3166_Name = @"VANUATU", ISO_3166_Alpha2Code = "VU", ISO_3166_Alpha3Code = "VUT", PhoneCode = "+678", CurrencyCode = "VUV", NetEntCountryName = "VANUATU" });
            countries.Add(new CountryInfo() { InternalID = 237, EnglishName = "Venezuela", ISO_3166_Name = @"VENEZUELA", ISO_3166_Alpha2Code = "VE", ISO_3166_Alpha3Code = "VEN", PhoneCode = "+58", CurrencyCode = "VEB", NetEntCountryName = "VENEZUELA" });
            countries.Add(new CountryInfo() { InternalID = 238, EnglishName = "Viet Nam", ISO_3166_Name = @"VIET NAM", ISO_3166_Alpha2Code = "VN", ISO_3166_Alpha3Code = "VNM", PhoneCode = "+84", CurrencyCode = "VND", NetEntCountryName = "VIET NAM" });
            countries.Add(new CountryInfo() { InternalID = 240, EnglishName = "Virgin Islands, British", ISO_3166_Name = @"VIRGIN ISLANDS, BRITISH", ISO_3166_Alpha2Code = "VG", ISO_3166_Alpha3Code = "VGB", PhoneCode = "+1-284", CurrencyCode = "USD", NetEntCountryName = "VIRGIN ISLANDS, BRITISH" });
            countries.Add(new CountryInfo() { InternalID = 239, EnglishName = "Virgin Islands, U.s.", ISO_3166_Name = @"VIRGIN ISLANDS, U.S.", ISO_3166_Alpha2Code = "VI", ISO_3166_Alpha3Code = "VIR", PhoneCode = "+1-340", CurrencyCode = "USD", NetEntCountryName = "VIRGIN ISLANDS, U.S." });
            countries.Add(new CountryInfo() { InternalID = 241, EnglishName = "Wallis and Futuna", ISO_3166_Name = @"WALLIS AND FUTUNA", ISO_3166_Alpha2Code = "WF", ISO_3166_Alpha3Code = "WLF", PhoneCode = "+681", CurrencyCode = "XPF", NetEntCountryName = "WALLIS AND FUTUNA" });
            countries.Add(new CountryInfo() { InternalID = 242, EnglishName = "Western Sahara", ISO_3166_Name = @"WESTERN SAHARA", ISO_3166_Alpha2Code = "EH", ISO_3166_Alpha3Code = "ESH", PhoneCode = "+212", CurrencyCode = "MAD", NetEntCountryName = "WESTERN SAHARA" });
            countries.Add(new CountryInfo() { InternalID = 243, EnglishName = "Yemen", ISO_3166_Name = @"YEMEN", ISO_3166_Alpha2Code = "YE", ISO_3166_Alpha3Code = "YEM", PhoneCode = "+967", CurrencyCode = "YER", NetEntCountryName = "YEMEN" });
            countries.Add(new CountryInfo() { InternalID = 245, EnglishName = "Zambia", ISO_3166_Name = @"ZAMBIA", ISO_3166_Alpha2Code = "ZM", ISO_3166_Alpha3Code = "ZMB", PhoneCode = "+260", CurrencyCode = "ZMK", NetEntCountryName = "Zaire see CONGO, THE DEMOCRATIC REPUBLIC OF THE  ZAMBIA" });
            countries.Add(new CountryInfo() { InternalID = 246, EnglishName = "Zimbabwe", ISO_3166_Name = @"ZIMBABWE", ISO_3166_Alpha2Code = "ZW", ISO_3166_Alpha3Code = "ZWE", PhoneCode = "+263", CurrencyCode = "ZWD", NetEntCountryName = "ZIMBABWE" });

            #endregion

            string srcPath = Path.Combine(SOURCE_BASE_DIR, @"App_GlobalResources\Countries.resx");
            if (!File.Exists(srcPath))
                return;
            ResXResourceReader reader = new ResXResourceReader(srcPath);
            Dictionary<string, object> dic = new Dictionary<string,object>(StringComparer.OrdinalIgnoreCase);
            foreach (DictionaryEntry entry in reader)
            {
                dic.Add(entry.Key as string, null);
            }

            foreach (CountryInfo country in countries)
            {
                string toName = Regex.Replace( country.ISO_3166_Name, @"[^\w_]", "_");
                string fromName = country.EnglishName.Replace(" ", string.Empty);

                switch (fromName)
                {
                    case "BosniaandHerzegovina": fromName = "BosniaAndHerzegowina"; break;
                    case "Congo,theDemocraticRepublicofthe": fromName = "Congo"; break;
                    case "CoteD'Ivoire": fromName = "CoteDIvoire"; break;
                    case "FalklandIslands(Malvinas)": fromName = "FalklandIslands"; break;
                    case "Guinea-Bissau": fromName = "GuineaBissau"; break;
                    case "HeardIslandandMcdonaldIslands": fromName = "HeardAndMcDonaldIslands"; break;
                    case "HolySee(VaticanCityState)": fromName = "VaticanCityState"; break;
                    case "Iran,IslamicRepublicof": fromName = "Iran"; break;
                    case "Korea,DemocraticPeople'sRepublicof": fromName = "SouthKoreaRepublicOfKorea"; break;
                    case "Korea,Republicof": fromName = "NorthKoreaPeoplesRepublicOfKorea"; break;
                    case "LaoPeople'sDemocraticRepublic": fromName = "LaoPeoplesRepublic"; break;
                    case "Macao": fromName = "Macau"; break;
                    case "Macedonia,theFormerYugoslavRepublicof": fromName = "Macedonia"; break;
                    case "Micronesia,FederatedStatesof": fromName = "Micronesia"; break;
                    case "Moldova,Republicof": fromName = "Moldova"; break;
                    case "SaintHelena": fromName = "StHelena"; break;
                    case "SaintPierreandMiquelon": fromName = "StPierreandMiquelon"; break;
                    case "SerbiaandMontenegro": fromName = "Serbia"; break;
                    case "SvalbardandJanMayen": fromName = "SvalbardAndJanMayenIslands"; break;
                    case "Taiwan,ProvinceofChina": fromName = "Taiwan"; break;
                    case "Tanzania,UnitedRepublicof": fromName = "Tanzania"; break;
                    case "Timor-Leste": fromName = "EastTimor"; break;
                    case "VirginIslands,British": fromName = "VirginIslandsBritish"; break;
                    case "VirginIslands,U.s.": fromName = "VirginIslandsUS"; break;
                    case "WallisandFutuna": fromName = "WallisAndFutunaIslands"; break;
                    case "Cocos(Keeling)Islands":  break;
                    case "PalestinianTerritory,Occupied": break;//
                }
                   
                //if (!dic.ContainsKey(fromName))
                //    continue;

                CopyResource(@"App_GlobalResources\Countries.resx", fromName, string.Format(@"Metadata\Country\.{0}", toName));

                

                DataTable dt = new DataTable();
                using (SqlConnection conn = new SqlConnection(DB_CONNECTION_STR))
                {
                    conn.Open();
                    using (SqlCommand cmd = new SqlCommand("SELECT * FROM cmRegion WHERE CountryID = @CountryID", conn))
                    {
                        cmd.Parameters.Add(new SqlParameter("@CountryID", country.InternalID));
                        using (SqlDataAdapter adapter = new SqlDataAdapter())
                        {
                            adapter.SelectCommand = cmd;
                            adapter.Fill(dt);
                        }
                    }
                }

                foreach (DataRow dr in dt.Rows)
                {
                    string temp2 = string.Format("{0}Metadata\\Regions\\.{1}_{2}"
                        , DESTINATION_BASE_DIR
                        , country.ISO_3166_Alpha2Code
                        , dr["ID"]);

                    using (StreamWriter sw = new StreamWriter(temp2, false, Encoding.UTF8))
                    {
                        sw.Write(dr["RegionName"] as string);
                        sw.Flush();
                    }
                }
            }
        }
        #endregion


        private static void CreateMetadata(string directory)
        {
            string file = Path.Combine(DESTINATION_BASE_DIR, directory);
            if( !Directory.Exists(file) )
                Directory.CreateDirectory(file);
            file = Path.Combine( file, ".properties.xml");
            using (StreamWriter sw = new StreamWriter( file, false, Encoding.UTF8 ))
            {
                sw.Write(@"<?xml version=""1.0"" encoding=""utf-8"" standalone=""yes""?>
<root>
  <Type>Metadata</Type>
</root>");
            }
        }

        private static void CopyResource(string sourceFile, string sourceEntry, string destination)
        {
            string srcPath = Path.Combine(SOURCE_BASE_DIR, sourceFile);
            string srcDir = Path.GetDirectoryName(srcPath);
            string srcFilename = Path.GetFileNameWithoutExtension(srcPath);

            Dictionary<string, ResxLangInfo> dic = new Dictionary<string, ResxLangInfo>(StringComparer.OrdinalIgnoreCase);

            if (!Directory.Exists(srcDir))
                return;

            string[] files = Directory.GetFiles(srcDir, string.Format("{0}*.resx", srcFilename), SearchOption.TopDirectoryOnly);
            foreach (string file in files)
            {
                string temp = Path.GetFileNameWithoutExtension(file);
                temp = temp.Substring(srcFilename.Length).TrimStart('.');

                Match m = Regex.Match(temp, @"^(?<distinctName>(\w+\.)?)(?<lang>(sr|he|el|es|de|pl|cs|ru|fr|zh\-cn|it|pt|zh|nl|da|sv|no|hu|uk|tr))$", RegexOptions.Compiled);
                if (m.Success)
                {
                    string distinctName = m.Groups["distinctName"].Value;
                    string lang = m.Groups["lang"].Value;

                    ResxLangInfo info;
                    if (!dic.TryGetValue( lang, out info))
                    {
                        info = new ResxLangInfo();
                        dic[lang] = info;
                    }
                    if (!string.IsNullOrEmpty(distinctName))
                        info.SpericalLangFile = file;
                    else
                        info.GenericLangFile = file;
                }
            }

            string destPath = Path.Combine(DESTINATION_BASE_DIR, destination);
            foreach (KeyValuePair<string, ResxLangInfo> pair in dic)
            {
                string tempFilename = pair.Value.GenericLangFile;
                if( string.IsNullOrEmpty(tempFilename) )
                    tempFilename = pair.Value.SpericalLangFile;
                ResXResourceReader reader
                    = new ResXResourceReader(tempFilename);
                string value = null;
                foreach (DictionaryEntry entry in reader)
                {
                    if (string.Compare(entry.Key as string, sourceEntry, true) == 0)
                    {
                        value = entry.Value as string;
                        break;
                    }
                }
                reader.Close();
                if (string.IsNullOrWhiteSpace(value))
                {
                    Console.WriteLine(string.Format("WARNING: can't locate the value for [{0}] in file {1}.", sourceEntry, Path.GetFileName(tempFilename)));
                    continue;
                }

                string temp = string.Format("{0}.{1}", destPath, pair.Key);
                if (!File.Exists(temp))
                {
                    using (StreamWriter sw = new StreamWriter(temp, false, Encoding.UTF8))
                    {
                        sw.Write(value);
                        sw.Flush();
                    }
                }
            }

            if( File.Exists(srcPath) )
            {
                ResXResourceReader reader = new ResXResourceReader(srcPath);
                string value = null;
                foreach (DictionaryEntry entry in reader)
                {
                    if (string.Compare(entry.Key as string, sourceEntry, true) == 0)
                    {
                        value = entry.Value as string;
                        break;
                    }
                }
                reader.Close();
                if (string.IsNullOrWhiteSpace(value))
                {
                    Console.WriteLine(string.Format("WARNING: can't locate the value for [{0}] in file {1}.", sourceEntry, Path.GetFileName(sourceFile) ));
                    return;
                }
                if (!File.Exists(destPath))
                {
                    string destDir = Path.GetDirectoryName(destPath);
                    if (!Directory.Exists(destDir))
                        Directory.CreateDirectory(destDir);
                    using (StreamWriter sw = new StreamWriter(destPath + ".ka", false, Encoding.UTF8))
                    {
                        sw.Write(value);
                        sw.Flush();
                    }
                }
            }
        }
    }

    [Serializable]
    public sealed class CountryInfo
    {
        public int InternalID { get; set; } // the id for relation-ship to GmCore
        public string ISO_3166_Name { get; set; }
        public string ISO_3166_Alpha2Code { get; set; }
        public string ISO_3166_Alpha3Code { get; set; }
        public string EnglishName { get; set; }
        public string NetEntCountryName { get; set; }

        public bool IsPhoneMandatory { get; set; }
        public bool RestrictRegistrationByIP { get; set; }
        public bool DisplayInRegistrationForm { get; set; }
        public bool DisplayInProfileForm { get; set; }
        public string PhoneCode { get; set; }
        public string CurrencyCode { get; set; }


        public bool IsInEuropeanEconomicArea
        {
            get { return true; }
        }

        public CountryInfo()
        {
            this.DisplayInRegistrationForm = true;
            this.DisplayInProfileForm = true;
            this.IsPhoneMandatory = true;
        }
    }
}
