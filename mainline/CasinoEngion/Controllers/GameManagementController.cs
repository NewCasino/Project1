using System;
using System.Collections.Generic;
using System.Configuration;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Hosting;
using System.Web.Mvc;
using System.Threading.Tasks;

using BLToolkit.Data;
using BLToolkit.DataAccess;
using CE.db;
using CE.db.Accessor;
using CE.Extensions;
using CE.Integration.Metadata;
using CE.Utils;
using GamMatrixAPI;
using Newtonsoft.Json;
using OfficeOpenXml;

namespace CasinoEngine.Controllers
{
    public enum AvailableEditGameProperty
    {
        Enabled,
        License,
        Width,
        Height,
        FPP,
        BonusContribution,
        PopularityCoefficient,
        AnonymousFunMode,
        FunMode,
        RealMode,
        NewGame,
        NewGameExpirationDate,
        Tags,
        OpVisible,
        JackpotType,

        InvoicingGroup,
        ReportingCategory,

        ExcludeFromBonuses,
        ExcludeFromBonuses_EditableByOperator,

        SupportFreeSpinBonus,

        LaunchGameInHtml5,
        AgeLimit
    }

    public enum PropertyEditType
    {
        Add,
        Override,
        Delete,
    }

    [SystemAuthorize]
    public class GameManagementController : Controller
    {
        public static PropertyInfo[] CeCasinoGameBaseProperties = null;
        public static PropertyInfo[] CeCasinoGameDomainProperties = null;
        //
        // GET: /GameManagement/

        public ActionResult Index()
        {
            return View();
        }

        [HttpGet]
        public ActionResult GameEditorDialog(long? id)
        {
            var domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == DomainManager.CurrentDomainID);
            if (domain == null && DomainManager.GetSysDomain().DomainID == DomainManager.CurrentDomainID)
                domain = DomainManager.GetSysDomain();

            if (domain == null)
                throw new Exception("domain can't be found");

            this.ViewData["newStatusCasinoGameExpirationDays"] = domain.NewStatusCasinoGameExpirationDays;

            ceCasinoGameBaseEx game = null;
            if (id.HasValue && id.Value > 0)
            {
                game = CasinoGameAccessor.GetDomainGame(DomainManager.CurrentDomainID, id.Value);
            }
            if (game == null)
                game = new ceCasinoGameBaseEx()
                {
                    GameID = null,
                    FunMode = true,
                    RealMode = true,
                    AnonymousFunMode = true,
                    NewGame = true,
                    NewGameExpirationDate = DateTime.Now.AddDays(domain.NewStatusCasinoGameExpirationDays),
                    ClientCompatibility = ",PC,",
                    DomainID = 1000L,
                    PopularityCoefficient = 1.0M,
                    Languages = "",
                    LimitationXml = null,
                    LimitAmounts = new Dictionary<string, CasinoGameLimitAmount>(),
                };
            game.FPP = decimal.Round(100.0M * game.FPP, 3);
            game.TheoreticalPayOut = decimal.Round(100.0M * game.TheoreticalPayOut, 3);
            game.JackpotContribution = decimal.Round(100.0M * game.JackpotContribution, 3);
            game.ThirdPartyFee = decimal.Round(100.0M * game.ThirdPartyFee, 3);
            game.BonusContribution = decimal.Round(100.0M * game.BonusContribution, 3);
            game.PopularityCoefficient = game.PopularityCoefficient * 100 / 100;
            game.LimitAmounts = string.IsNullOrWhiteSpace(game.LimitationXml) ? new Dictionary<string, CasinoGameLimitAmount>() : Newtonsoft.Json.JsonConvert.DeserializeObject<Dictionary<string, CasinoGameLimitAmount>>(game.LimitationXml);

            return View("GameEditorDialog", game);
        }

        [HttpGet]
        public ActionResult GamePerprotyEditDialog()
        {
            var domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == DomainManager.CurrentDomainID);
            if (domain == null && DomainManager.GetSysDomain().DomainID == DomainManager.CurrentDomainID)
                domain = DomainManager.GetSysDomain();

            if (domain == null)
                throw new Exception("domain can't be found");

            this.ViewData["newStatusCasinoGameExpirationDays"] = domain.NewStatusCasinoGameExpirationDays;

            return View("GamePropertyEditorDialog");
        }

        private ActionResult ExportAsSpreadsheet(List<ceCasinoGameBaseEx> games)
        {
            try
            {

                using (ExcelPackage pck = new ExcelPackage())
                {
                    string path = HostingEnvironment.MapPath("~/App_Data/template.xlsx");
                    using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                    {
                        pck.Load(fs);
                    }

                    ExcelWorksheet ws = pck.Workbook.Worksheets[1];


                    for (int i = 0; i < games.Count; i++)
                    {
                        ceCasinoGameBaseEx game = games[i];
                        string row = (i + 2).ToString();

                        ws.Cells["A" + row].Value = game.ID.ToString();
                        ws.Cells["B" + row].Value = game.ShortName;
                        ws.Cells["C" + row].Value = game.VendorID.ToString();
                        ws.Cells["D" + row].Value = game.GameID;
                        ws.Cells["E" + row].Value = game.GameCode;

                        ws.Cells["F" + row].Value = (game.GameCategories ?? string.Empty).Trim(',');

                        ws.Cells["G" + row].Value = game.ReportCategory.ToString();
                        ws.Cells["H" + row].Value = game.InvoicingGroup.ToString();
                        ws.Cells["I" + row].Value = game.FunMode ? "Y" : "-";
                        ws.Cells["J" + row].Value = game.RealMode ? "Y" : "-";
                        ws.Cells["K" + row].Value = game.AnonymousFunMode ? "Y" : "-";

                        ws.Cells["L" + row].Value = game.JackpotContribution.ToString("F2");
                        ws.Cells["M" + row].Value = game.BonusContribution.ToString("F3");
                        ws.Cells["N" + row].Value = game.FPP.ToString("F2");
                        ws.Cells["O" + row].Value = game.TheoreticalPayOut.ToString("F3");
                        ws.Cells["P" + row].Value = game.ThirdPartyFee.ToString("F3");
                        ws.Cells["Q" + row].Value = game.PopularityCoefficient.ToString("F2");

                        ws.Cells["R" + row].Value = (game.Tags ?? string.Empty).Trim(',');
                        ws.Cells["S" + row].Value = game.Slug;
                        ws.Cells["T" + row].Value = (game.ClientCompatibility ?? string.Empty).Trim(',');
                        ws.Cells["U" + row].Value = game.License.ToString();
                        ws.Cells["V" + row].Value = game.JackpotType.ToString();
                        ws.Cells["W" + row].Value = (game.RestrictedTerritories ?? string.Empty).Trim(',');
                        ws.Cells["X" + row].Value = game.NewGame ? "New Game" : string.Empty;
                        ws.Cells["Y" + row].Value = game.Description;
                        ws.Cells["Z" + row].Value = game.LaunchGameInHtml5;
                        ws.Cells["AA" + row].Value = game.AgeLimit;
                    }




                    string filename = string.Format("{0}-{1}-{2}_{3}-{4}-{5}_{6}games.xlsx"
                        , DateTime.Now.Year
                        , DateTime.Now.Month
                        , DateTime.Now.Day
                        , DateTime.Now.Hour
                        , DateTime.Now.Minute
                        , DateTime.Now.Second
                        , games.Count
                        );
                    return this.File(pck.GetAsByteArray()
                        , "application/octet-stream"
                        , filename
                        );
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Content(ex.Message, "text/plain");
            }
        }

        [HttpPost]
        public ActionResult GameList(long domainID
            , VendorID[] filteredVendorIDs
            , string[] filteredCategories
            , string filteredReportCategory
            , string filteredInvoicingGroup
            , string filteredClientType
            , string filteredAvailability
            , string filteredGameName
            , string filteredGameCode
            , string filteredTag
            , string filteredID
            , string filteredSlug
            , LicenseType? filteredLicense
            , string filteredOpVisible
            , string filteredExcludeFromBonuses
            , int? pageIndex
            , int pageSize
            , bool? exportAsSpreadsheet
            )
        {
            if (!exportAsSpreadsheet.HasValue)
                exportAsSpreadsheet = false;

            if (!pageIndex.HasValue) pageIndex = 1;

            Dictionary<string, object> parameters = new Dictionary<string, object>();

            if (!string.IsNullOrWhiteSpace(filteredID))
                parameters.Add("ID", filteredID);

            if (!string.IsNullOrWhiteSpace(filteredSlug))
                parameters.Add("Slug", filteredSlug);

            parameters.Add("VendorID", filteredVendorIDs);

            if (filteredCategories != null)
                parameters.Add("GameCategories", filteredCategories);


            if (!string.IsNullOrWhiteSpace(filteredReportCategory))
                parameters.Add("ReportCategory", filteredReportCategory);

            if (!string.IsNullOrWhiteSpace(filteredInvoicingGroup))
                parameters.Add("InvoicingGroup", filteredInvoicingGroup);

            if (!string.IsNullOrWhiteSpace(filteredClientType))
                parameters.Add("ClientCompatibility", filteredClientType);

            if (!string.IsNullOrWhiteSpace(filteredAvailability))
                parameters.Add("Enabled", filteredAvailability == "1");

            if (filteredLicense.HasValue)
                parameters.Add("License", filteredLicense.Value);

            if (!string.IsNullOrWhiteSpace(filteredGameName))
                parameters.Add("GameName", filteredGameName);

            if (!string.IsNullOrWhiteSpace(filteredGameCode))
                parameters.Add("GameCode", filteredGameCode);

            if (!string.IsNullOrWhiteSpace(filteredTag))
                parameters.Add("Tags", filteredTag);
            if (!string.IsNullOrWhiteSpace(filteredOpVisible))
            {
                parameters.Add("OpVisible", filteredOpVisible == "1");
            }
            if (!string.IsNullOrWhiteSpace(filteredExcludeFromBonuses))
            {
                parameters.Add("ExcludeFromBonuses", filteredExcludeFromBonuses == "1");
            }
            
            if (exportAsSpreadsheet.Value)
            {
                pageIndex = 1;
                pageSize = 9999999;
            }

            int totalCount = 0;
            List<ceCasinoGameBaseEx> games = CasinoGameAccessor.SearchGames(pageIndex.Value, pageSize, domainID, parameters, out totalCount, false, CurrentUserSession.UserDomainID != Constant.SystemDomainID);

            if (exportAsSpreadsheet.Value)
            {
                return ExportAsSpreadsheet(games);
            }

            if (domainID == Constant.SystemDomainID)
                this.ViewData["BaseGameList"] = games;
            else
            {
                List<ceCasinoGameBaseEx> baseGames = CasinoGameAccessor.GetBaseGames(games.Select(g => g.ID).ToArray<long>());
                this.ViewData["BaseGameList"] = baseGames;
                //this.ViewData["BaseGameList"] = CasinoGameAccessor.SearchGames(pageIndex.Value, pageSize, Constant.SystemDomainID, parameters); 
            }

            int totalPageCount = (int)Math.Ceiling(totalCount / (1.0f * pageSize));
            if (pageIndex.Value > totalPageCount)
                pageIndex = totalPageCount;

            this.ViewData["filteredVendorIDs"] = filteredVendorIDs;
            this.ViewData["filteredCategories"] = filteredCategories;
            this.ViewData["filteredReportCategory"] = filteredReportCategory;
            this.ViewData["filteredInvoicingGroup"] = filteredInvoicingGroup;
            this.ViewData["filteredClientType"] = filteredClientType;
            this.ViewData["filteredAvailability"] = filteredAvailability;
            this.ViewData["filteredGameName"] = filteredGameName;
            this.ViewData["filteredGameCode"] = filteredGameCode;
            this.ViewData["filteredTag"] = filteredTag;
            this.ViewData["filteredSlug"] = filteredSlug;
            this.ViewData["filteredID"] = filteredID;
            if (filteredLicense.HasValue)
                this.ViewData["filteredLicense"] = filteredLicense.Value.ToString();
            this.ViewData["filteredOpVisible"] = filteredOpVisible;
            this.ViewData["filteredExcludeFromBonuses"] = filteredExcludeFromBonuses;
            this.ViewData["pageIndex"] = pageIndex.Value;
            this.ViewData["pageSize"] = pageSize;
            this.ViewData["pageCount"] = totalPageCount;
            this.ViewData["totalRecords"] = totalCount; //games.Count;

            int _temp = pageSize * pageIndex.Value;
            if (_temp > totalCount) _temp = totalCount;
            this.ViewData["currentRecords"] = _temp;
            return View("GameList", games);
        }


        [HttpPost]
        public ContentResult SaveGame(ceCasinoGameBase updatedGame
            , HttpPostedFileBase thumbnailFile
            , HttpPostedFileBase logoFile
            , HttpPostedFileBase backgroundImageFile
            , HttpPostedFileBase iconFile
            , HttpPostedFileBase scalableThumbnailFile
            )
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            using (DbManager db = new DbManager())
            {
                db.BeginTransaction();
                try
                {

                    if (string.IsNullOrWhiteSpace(updatedGame.GameID))
                        throw new ArgumentNullException("gameID");

                    if (!string.IsNullOrWhiteSpace(updatedGame.Slug))
                    {
                        updatedGame.Slug = Regex.Replace(updatedGame.Slug, @"[^a-z_\-\d]", string.Empty, RegexOptions.CultureInvariant | RegexOptions.IgnoreCase | RegexOptions.ECMAScript|RegexOptions.Compiled);
                        if (Regex.IsMatch(updatedGame.Slug, "^(\\d+)$", RegexOptions.CultureInvariant| RegexOptions.Compiled))
                            throw new Exception("The slug can not only contain digits.");
                    }

                    if (!string.IsNullOrWhiteSpace(updatedGame.SpinLines))
                    { 
                        if(!updatedGame.IsSpinLinesValid())
                            throw new Exception("Please enter correct spin lines.");
                    }

                    if (!string.IsNullOrWhiteSpace(updatedGame.SpinCoins))
                    {
                        if (!updatedGame.IsSpinCoinsValid())
                            throw new Exception("Please enter correct spin coins.");
                    }

                    string thumbnailFilePath = null;
                    string logoFilePath = null;
                    string backgroundImageFilePath = null;
                    string scalableThumbnailFileName = null;
                    string iconFilePath = null;
                    #region Save Image
                    {
                        string imageFileName;
                        byte[] imageBuffer;
                        if (ImageAsset.ParseImage(backgroundImageFile, out imageFileName, out imageBuffer))
                        {
                            backgroundImageFilePath = ImageAsset.GetImageFtpFilePath(imageFileName);
                            FTP.UploadFile(DomainManager.CurrentDomainID, backgroundImageFilePath, imageBuffer);
                        }

                        if (ImageAsset.ParseImage(thumbnailFile, out imageFileName, out imageBuffer))
                        {
                            thumbnailFilePath = ImageAsset.GetImageFtpFilePath(imageFileName);
                            FTP.UploadFile(DomainManager.CurrentDomainID, thumbnailFilePath, imageBuffer);
                        }

                        if (ImageAsset.ParseImage(logoFile, out imageFileName, out imageBuffer))
                        {
                            using (MemoryStream ms = new MemoryStream(imageBuffer))
                            using (Bitmap bitmap = new Bitmap(ms))
                            {
                                if (bitmap.Width != 120 || bitmap.Height != 120)
                                    throw new Exception("The dimensions of logo must be 120px X 120px.");
                            }
                            logoFilePath = ImageAsset.GetImageFtpFilePath(imageFileName);
                            FTP.UploadFile(DomainManager.CurrentDomainID, logoFilePath, imageBuffer);
                        }

                        if (ImageAsset.ParseImage(iconFile, out imageFileName, out imageBuffer))
                        {
                            using (MemoryStream ms = new MemoryStream(imageBuffer))
                            using (Bitmap bitmap = new Bitmap(ms))
                            {
                                if (bitmap.Width != 114 || bitmap.Height != 114)
                                    throw new Exception("The dimensions of logo must be 114px X 114px.");

                                iconFilePath = string.Format("/_casino/{0}/{{0}}_{1}"
                                    , imageFileName[0]
                                    , imageFileName
                                    );

                                int[] sizes = new int[] { 114, 88, 72, 57, 44, 22 };
                                foreach (int size in sizes)
                                {
                                    string ftpFilePath = string.Format(iconFilePath, size);

                                    using (MemoryStream dest = new MemoryStream())
                                    using (Image thumbnail = bitmap.GetThumbnailImage(size, size, ThumbnailCallback, IntPtr.Zero))
                                    {
                                        thumbnail.Save(dest, bitmap.RawFormat);
                                        imageBuffer = dest.ToArray();
                                    }

                                    FTP.UploadFile(DomainManager.CurrentDomainID, ftpFilePath, imageBuffer);
                                }
                            }
                        }

                        if (ImageAsset.ParseImage(scalableThumbnailFile, out scalableThumbnailFileName, out imageBuffer))
                        {
                            using (MemoryStream ms = new MemoryStream(imageBuffer))
                            using (Bitmap bitmap = new Bitmap(ms))
                            {
                                DomainConfigAccessor dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
                                ceDomainConfigEx domain = dca.GetByDomainID(DomainManager.CurrentDomainID);

                                if (bitmap.Width != (domain.ScalableThumbnailWidth == 0 ? 376 : domain.ScalableThumbnailWidth) ||
                                    bitmap.Height != (domain.ScalableThumbnailHeight == 0 ? 250 : domain.ScalableThumbnailHeight))
                                    throw new Exception("The dimensions of scalable thumbnail must be 376px X 250px.");

                                string scalableThumbnailFilePath = ImageAsset.GetImageFtpFilePath(scalableThumbnailFileName);
                                FTP.UploadFile(DomainManager.CurrentDomainID, scalableThumbnailFilePath, imageBuffer);

                                SqlQuery<ceScalableThumbnail> stq = new SqlQuery<ceScalableThumbnail>(db);
                                if (null == stq.SelectByKey(scalableThumbnailFileName, bitmap.Width, bitmap.Height))
                                {
                                    ceScalableThumbnail st = new ceScalableThumbnail()
                                    {
                                        OrginalFileName = scalableThumbnailFileName,
                                        Width = bitmap.Width,
                                        Height = bitmap.Height,
                                        FilePath = scalableThumbnailFilePath,
                                        DomainID = DomainManager.CurrentDomainID,
                                    };
                                    stq.Insert(st);
                                }
                            }
                        }
                    }
                    #endregion

                    updatedGame.BonusContribution /= 100.00M;
                    updatedGame.FPP /= 100.00M;
                    updatedGame.JackpotContribution /= 100.00M;
                    updatedGame.TheoreticalPayOut /= 100.00M;
                    updatedGame.ThirdPartyFee /= 100.00M;

                    CasinoGameAccessor cga = CasinoGameAccessor.CreateInstance<CasinoGameAccessor>(db);

                    // add game
                    if (DomainManager.CurrentDomainID == Constant.SystemDomainID)
                    {
                        SqlQuery<ceCasinoGameBase> query = new SqlQuery<ceCasinoGameBase>(db);

                        ceCasinoGameBase game = null;

                        if (updatedGame.ID > 0)
                            game = query.SelectByKey(updatedGame.ID);
                        if (game == null)
                        {
                            game = new ceCasinoGameBase();
                            game.Ins = DateTime.Now;
                            game.SessionUserID = CurrentUserSession.UserID;
                            game.SessionID = CurrentUserSession.UserSessionID;
                            game.VendorID = updatedGame.VendorID;
                            game.Enabled = true;
                        }
                        game.OriginalVendorID = updatedGame.OriginalVendorID;
                        game.ContentProviderID = updatedGame.ContentProviderID;
                        game.DomainID = Constant.SystemDomainID;
                        game.Description = updatedGame.Description.DefaultIfNullOrEmpty(string.Empty);
                        game.GameLaunchUrl = updatedGame.GameLaunchUrl;
                        game.MobileGameLaunchUrl = updatedGame.MobileGameLaunchUrl;
                        game.AnonymousFunMode = updatedGame.AnonymousFunMode;
                        game.FunMode = updatedGame.FunMode;
                        game.RealMode = updatedGame.RealMode;
                        game.NewGame = updatedGame.NewGame;
                        game.NewGameExpirationDate = updatedGame.NewGame ? updatedGame.NewGameExpirationDate : DateTime.Now.AddDays(-1);
                        game.GameCategories = updatedGame.GameCategories.DefaultIfNullOrEmpty(string.Empty);
                        game.RestrictedTerritories = (updatedGame.RestrictedTerritories ?? string.Empty).Trim(',');
                        game.ClientCompatibility = updatedGame.ClientCompatibility.DefaultIfNullOrEmpty(string.Empty);
                        game.GameID = updatedGame.GameID;
                        switch (game.VendorID)
                        {
                            case VendorID.Microgaming:
                            case VendorID.PlaynGO:
                            case VendorID.Sheriff:
                            case VendorID.OMI:
                            case VendorID.EvolutionGaming:
                            case VendorID.ISoftBet:
                            case VendorID.Ezugi:
                            case VendorID.Vivo:
                            case VendorID.TTG:
                            case VendorID.GoldenRace:
                                game.GameCode = updatedGame.GameCode;
                                break;
                            case VendorID.NetEnt:
                                //game.Limit = NetEntAPI.LiveCasinoTable.Get(DomainManager.CurrentDomainID, game.GameID, game.ExtraParameter1).Limitation;
                                game.GameCode = game.GameID;
                                break;
                            default:
                                game.GameCode = game.GameID;
                                break;
                        }
                        game.ExtraParameter1 = updatedGame.ExtraParameter1;
                        game.ExtraParameter2 = updatedGame.ExtraParameter2;
                        game.ThirdPartyFee = updatedGame.ThirdPartyFee;
                        game.InvoicingGroup = updatedGame.InvoicingGroup;
                        game.GameName = updatedGame.GameName;
                        game.ReportCategory = updatedGame.ReportCategory;
                        game.ShortName = updatedGame.ShortName;
                        game.Tags = RemoveDuplicateData(updatedGame.Tags);
                        game.FPP = updatedGame.FPP;
                        game.BonusContribution = updatedGame.BonusContribution;
                        game.JackpotContribution = updatedGame.JackpotContribution;
                        game.TheoreticalPayOut = updatedGame.TheoreticalPayOut;
                        game.Width = updatedGame.Width;
                        game.Height = updatedGame.Height;

                        game.License = updatedGame.License;

                        game.JackpotType = updatedGame.JackpotType;
                        game.Languages = updatedGame.Languages;
                        game.AgeLimit = updatedGame.AgeLimit;
                        game.LaunchGameInHtml5 = updatedGame.LaunchGameInHtml5;

                        Dictionary<string, CasinoGameLimitAmount> limitAmounts = ParseLimit();
                        if (limitAmounts.Count > 0 )
                        {
                            game.LimitationXml = Newtonsoft.Json.JsonConvert.SerializeObject(limitAmounts);
                        }
                        game.Slug = string.IsNullOrWhiteSpace(updatedGame.Slug) ? null : updatedGame.Slug.ToLowerInvariant();
                        game.PopularityCoefficient = updatedGame.PopularityCoefficient;

                        game.DefaultCoin = updatedGame.DefaultCoin;

                        game.ExcludeFromBonuses = updatedGame.ExcludeFromBonuses;
                        game.ExcludeFromBonuses_EditableByOperator = updatedGame.ExcludeFromBonuses_EditableByOperator;

                        game.SpinLines = updatedGame.SpinLines;
                        game.SpinCoins = updatedGame.SpinCoins;
                        game.SpinDenominations = updatedGame.SpinDenominations;

                        game.SupportFreeSpinBonus = updatedGame.SupportFreeSpinBonus;
                        game.FreeSpinBonus_DefaultLine = updatedGame.FreeSpinBonus_DefaultLine;
                        game.FreeSpinBonus_DefaultCoin = updatedGame.FreeSpinBonus_DefaultCoin;
                        game.FreeSpinBonus_DefaultDenomination = updatedGame.FreeSpinBonus_DefaultDenomination;

                        if (!string.IsNullOrWhiteSpace(thumbnailFilePath))
                            game.Thumbnail = thumbnailFilePath;

                        if (!string.IsNullOrWhiteSpace(scalableThumbnailFileName))
                            game.ScalableThumbnail = scalableThumbnailFileName;

                        if (!string.IsNullOrWhiteSpace(logoFilePath))
                            game.Logo = logoFilePath;

                        if (!string.IsNullOrWhiteSpace(backgroundImageFilePath))
                            game.BackgroundImage = backgroundImageFilePath;

                        if (!string.IsNullOrWhiteSpace(iconFilePath))
                            game.Icon = iconFilePath;

                        if (updatedGame.ID > 0)
                        {
                            query.Update(db, game);
                            cga.BackupCasinoGameBase(CurrentUserSession.UserSessionID, CurrentUserSession.UserID, game.ID, DateTime.Now);
                        }
                        else
                        {
                            query.Insert(db, game);
                            cga.BackupCasinoGameBase(CurrentUserSession.UserSessionID, CurrentUserSession.UserID, 0, DateTime.Now);
                        }

                    }
                    else if (updatedGame.ID > 0)
                    {
                        ceCasinoGameBase gameBase = null;
                        {
                            SqlQuery<ceCasinoGameBase> query1 = new SqlQuery<ceCasinoGameBase>(db);
                            gameBase = query1.SelectByKey(updatedGame.ID);
                        }


                        SqlQuery<ceCasinoGame> query2 = new SqlQuery<ceCasinoGame>(db);

                        ceCasinoGame domainGame = cga.QueryDomainGame(DomainManager.CurrentDomainID, updatedGame.ID);
                        bool isExist = domainGame != null;
                        if (!isExist)
                        {
                            domainGame = new ceCasinoGame();
                            domainGame.RestrictedTerritories = (gameBase.RestrictedTerritories ?? string.Empty).Trim(',');
                            domainGame.DomainID = DomainManager.CurrentDomainID;
                            domainGame.Ins = DateTime.Now;
                            domainGame.Enabled = gameBase.Enabled;
                            domainGame.CasinoGameBaseID = updatedGame.ID;
                            domainGame.SessionID = CurrentUserSession.UserSessionID;
                            domainGame.SessionUserID = CurrentUserSession.UserID;
                            domainGame.OpVisible = gameBase.OpVisible;
                            domainGame.ExcludeFromBonuses = gameBase.ExcludeFromBonuses;
                            domainGame.ExcludeFromBonuses_EditableByOperator = gameBase.ExcludeFromBonuses_EditableByOperator;
                            domainGame.NewGameExpirationDate = gameBase.NewGame ? gameBase.NewGameExpirationDate : DateTime.Now.AddDays(-1);
                        }


                        #region Merge Attributes

                        if (CurrentUserSession.UserDomainID == Constant.SystemDomainID)
                        {
                            domainGame.RestrictedTerritories = (updatedGame.RestrictedTerritories ?? string.Empty).Trim(',');
                            // real mode
                            if (updatedGame.RealMode != gameBase.RealMode)
                                domainGame.RealMode = updatedGame.RealMode;
                            else
                                domainGame.RealMode = null;

                            // fun mode
                            if (updatedGame.FunMode != gameBase.FunMode)
                                domainGame.FunMode = updatedGame.FunMode;
                            else
                                domainGame.FunMode = null;

                            // fun mode
                            if (updatedGame.AnonymousFunMode != gameBase.AnonymousFunMode)
                                domainGame.AnonymousFunMode = updatedGame.AnonymousFunMode;
                            else
                                domainGame.AnonymousFunMode = null;

                            //ExcludeFromBonuses
                            if (updatedGame.ExcludeFromBonuses != gameBase.ExcludeFromBonuses)
                                domainGame.ExcludeFromBonuses = updatedGame.ExcludeFromBonuses;
                            else
                                domainGame.ExcludeFromBonuses = null;

                            //ExcludeFromBonuses_EditableByOperator
                            if (updatedGame.ExcludeFromBonuses_EditableByOperator != gameBase.ExcludeFromBonuses_EditableByOperator)
                                domainGame.ExcludeFromBonuses_EditableByOperator = updatedGame.ExcludeFromBonuses_EditableByOperator;
                            else
                                domainGame.ExcludeFromBonuses_EditableByOperator = null;

                        }
                        else
                        {
                            //ExcludeFromBonuses
                            if (domainGame.ExcludeFromBonuses_EditableByOperator.HasValue && domainGame.ExcludeFromBonuses_EditableByOperator.Value)
                            {                                
                                if (updatedGame.ExcludeFromBonuses != gameBase.ExcludeFromBonuses)
                                    domainGame.ExcludeFromBonuses = updatedGame.ExcludeFromBonuses;
                                else
                                    domainGame.ExcludeFromBonuses = null;
                            }
                        }

                        // new game
                        if (updatedGame.NewGame != gameBase.NewGame || updatedGame.NewGameExpirationDate.CompareTo(gameBase.NewGameExpirationDate) != 0)
                        {
                            domainGame.NewGame = updatedGame.NewGame;
                            domainGame.NewGameExpirationDate = updatedGame.NewGame ? updatedGame.NewGameExpirationDate : DateTime.Now.AddDays(-1);
                        }
                        else
                            domainGame.NewGame = null;
                        //Launch Identifying
                        if (string.Equals(updatedGame.ExtraParameter1, gameBase.ExtraParameter1))
                        {
                            domainGame.ExtraParameter1 = null;
                        }
                        else
                        {
                            domainGame.ExtraParameter1 = updatedGame.ExtraParameter1;
                        }

                        // width
                        if (updatedGame.Width != gameBase.Width)
                            domainGame.Width = updatedGame.Width;
                        else
                            domainGame.Width = null;

                        // Height
                        if (updatedGame.Height != gameBase.Height)
                            domainGame.Height = updatedGame.Height;
                        else
                            domainGame.Height = null;

                        // client compatibility
                        if (updatedGame.ClientCompatibility != gameBase.ClientCompatibility)
                            domainGame.ClientCompatibility = updatedGame.ClientCompatibility;
                        else
                            domainGame.ClientCompatibility = null;

                        // report category
                        if (updatedGame.ReportCategory != gameBase.ReportCategory)
                            domainGame.ReportCategory = updatedGame.ReportCategory;
                        else
                            domainGame.ReportCategory = null;

                        // invoicing group
                        if (updatedGame.InvoicingGroup != gameBase.InvoicingGroup)
                            domainGame.InvoicingGroup = updatedGame.InvoicingGroup;
                        else
                            domainGame.InvoicingGroup = null;

                        // launch url group
                        if (updatedGame.GameLaunchUrl != gameBase.GameLaunchUrl)
                            domainGame.GameLaunchUrl = updatedGame.GameLaunchUrl;
                        else
                            domainGame.GameLaunchUrl = null;

                        if (updatedGame.MobileGameLaunchUrl != gameBase.MobileGameLaunchUrl)
                            domainGame.MobileGameLaunchUrl = updatedGame.MobileGameLaunchUrl;
                        else
                            domainGame.MobileGameLaunchUrl = null;

                        // Popularity Coefficient
                        if (updatedGame.PopularityCoefficient != gameBase.PopularityCoefficient)
                            domainGame.PopularityCoefficient = updatedGame.PopularityCoefficient;
                        else
                            domainGame.PopularityCoefficient = null;

                        /*
                        // Theoretical PayOut Percent
                        if (game.TheoreticalPayOut != gameBase.TheoreticalPayOut)
                            game.TheoreticalPayOut = game.TheoreticalPayOut;
                        else
                            game.TheoreticalPayOut = null;

                        // JackpotContribution
                        if (game.JackpotContribution != gameBase.JackpotContribution)
                            game.JackpotContribution = game.JackpotContribution;
                        else
                            game.JackpotContribution = null;
                           

                        // ThirdPartyFee
                        if (game.ThirdPartyFee != gameBase.ThirdPartyFee)
                            domainGame.ThirdPartyFee = game.ThirdPartyFee;
                        else
                            domainGame.ThirdPartyFee = null;
                        */
                        //////////////////////////////////////////////////////////////////
                        // the following fields can be modified by operator

                        // game categories
                        if (updatedGame.GameCategories != gameBase.GameCategories)
                            domainGame.GameCategories = updatedGame.GameCategories;
                        else
                            domainGame.GameCategories = null;

                        // FPP
                        if (updatedGame.FPP != gameBase.FPP)
                            domainGame.FPP = updatedGame.FPP;
                        else
                            domainGame.FPP = null;

                        // BonusContribution
                        if (updatedGame.BonusContribution != gameBase.BonusContribution)
                            domainGame.BonusContribution = updatedGame.BonusContribution;
                        else
                            domainGame.BonusContribution = null;

                        // Name
                        if (!string.IsNullOrWhiteSpace(updatedGame.GameName) &&
                            updatedGame.GameName != gameBase.GameName)
                        {
                            domainGame.GameName = updatedGame.GameName;
                        }
                        else
                            domainGame.GameName = null;

                        // ShortName
                        if (!string.IsNullOrWhiteSpace(updatedGame.ShortName) &&
                            updatedGame.ShortName != gameBase.ShortName)
                        {
                            domainGame.ShortName = updatedGame.ShortName;
                        }
                        else
                            domainGame.ShortName = null;

                        // Tags
                        string newTags = RemoveDuplicateData(updatedGame.Tags);
                        if (!string.IsNullOrWhiteSpace(newTags) && !string.Equals(newTags,gameBase.Tags))
                        {
                            domainGame.Tags = newTags;
                        }
                        else
                            domainGame.Tags = null;

                        // Description
                        if (!string.IsNullOrWhiteSpace(updatedGame.Description) &&
                            updatedGame.Description != gameBase.Description)
                        {
                            domainGame.Description = updatedGame.Description;
                        }
                        else
                            domainGame.Description = null;

                        // Thumbnail
                        if (!string.IsNullOrWhiteSpace(thumbnailFilePath))
                        {
                            if (thumbnailFilePath != gameBase.Thumbnail)
                                domainGame.Thumbnail = thumbnailFilePath;
                            else
                                domainGame.Thumbnail = null;
                        }
                        else if (string.IsNullOrWhiteSpace(domainGame.Thumbnail))
                            domainGame.Thumbnail = null;


                        // Scalable Thumbnail
                        if (!string.IsNullOrWhiteSpace(scalableThumbnailFileName))
                        {
                            if (scalableThumbnailFileName != gameBase.ScalableThumbnail)
                                domainGame.ScalableThumbnail = scalableThumbnailFileName;
                            else
                                domainGame.ScalableThumbnail = null;
                        }
                        else if (string.IsNullOrWhiteSpace(domainGame.ScalableThumbnail))
                            domainGame.ScalableThumbnail = null;

                        // Logo
                        if (!string.IsNullOrWhiteSpace(logoFilePath))
                        {
                            if (logoFilePath != gameBase.Logo)
                                domainGame.Logo = logoFilePath;
                            else
                                domainGame.Logo = null;
                        }
                        else if (string.IsNullOrWhiteSpace(domainGame.Logo))
                            domainGame.Logo = null;

                        // Icon
                        if (!string.IsNullOrWhiteSpace(iconFilePath))
                        {
                            if (iconFilePath != gameBase.Icon)
                                domainGame.Icon = iconFilePath;
                            else
                                domainGame.Icon = null;
                        }
                        else if (string.IsNullOrWhiteSpace(domainGame.Icon))
                            domainGame.Icon = null;

                        // Background image
                        if (!string.IsNullOrWhiteSpace(backgroundImageFilePath))
                        {
                            if (backgroundImageFilePath != gameBase.BackgroundImage)
                                domainGame.BackgroundImage = backgroundImageFilePath;
                            else
                                domainGame.BackgroundImage = null;
                        }
                        else if (string.IsNullOrWhiteSpace(domainGame.BackgroundImage))
                            domainGame.BackgroundImage = null;

                        // License
                        if (updatedGame.License != gameBase.License)
                            domainGame.License = updatedGame.License;
                        else
                            domainGame.License = null;

                        // JackpotType
                        if (updatedGame.JackpotType != gameBase.JackpotType)
                            domainGame.JackpotType = updatedGame.JackpotType;
                        else
                            domainGame.JackpotType = null;

                        // Languages
                        if (updatedGame.Languages != gameBase.Languages)
                        {
                            domainGame.Languages = updatedGame.Languages;
                        }
                        else
                        {
                            domainGame.Languages = null;
                        }

                        //LimitationXml
                        Dictionary<string, CasinoGameLimitAmount> limitAmounts = ParseLimit();
                        string limitationXml = null;
                        if (limitAmounts.Count > 0)
                        {
                            limitationXml = Newtonsoft.Json.JsonConvert.SerializeObject(limitAmounts);
                        }
                        if (string.Equals(limitationXml, domainGame.LimitationXml))
                        {
                            domainGame.LimitationXml = null;
                        }
                        else
                        {
                            domainGame.LimitationXml = limitationXml;
                        }
                        //DefaultCoin
                        if (updatedGame.DefaultCoin != gameBase.DefaultCoin)
                            domainGame.DefaultCoin = updatedGame.DefaultCoin;
                        else
                            domainGame.DefaultCoin = null;

                        if (updatedGame.SpinLines != gameBase.SpinLines)
                            domainGame.SpinLines = updatedGame.SpinLines;
                        else
                            domainGame.SpinLines = null;

                        if (updatedGame.SpinCoins != gameBase.SpinCoins)
                            domainGame.SpinCoins = updatedGame.SpinCoins;
                        else
                            domainGame.SpinCoins = null;

                        if (updatedGame.SpinDenominations != gameBase.SpinDenominations)
                            domainGame.SpinDenominations = updatedGame.SpinDenominations;
                        else
                            domainGame.SpinDenominations = null;

                        if (updatedGame.SupportFreeSpinBonus != gameBase.SupportFreeSpinBonus)
                            domainGame.SupportFreeSpinBonus = updatedGame.SupportFreeSpinBonus;
                        else
                            domainGame.SupportFreeSpinBonus = null;

                        if (updatedGame.FreeSpinBonus_DefaultLine != gameBase.FreeSpinBonus_DefaultLine)
                            domainGame.FreeSpinBonus_DefaultLine = updatedGame.FreeSpinBonus_DefaultLine;
                        else
                            domainGame.FreeSpinBonus_DefaultLine = null;

                        if (updatedGame.FreeSpinBonus_DefaultCoin != gameBase.FreeSpinBonus_DefaultCoin)
                            domainGame.FreeSpinBonus_DefaultCoin = updatedGame.FreeSpinBonus_DefaultCoin;
                        else
                            domainGame.FreeSpinBonus_DefaultCoin = null;

                        if (updatedGame.FreeSpinBonus_DefaultDenomination != gameBase.FreeSpinBonus_DefaultDenomination)
                            domainGame.FreeSpinBonus_DefaultDenomination = updatedGame.FreeSpinBonus_DefaultDenomination;
                        else
                            domainGame.FreeSpinBonus_DefaultDenomination = null;

                        if (updatedGame.AgeLimit != gameBase.AgeLimit)
                            domainGame.AgeLimit = updatedGame.AgeLimit;
                        else
                            domainGame.AgeLimit = null;

                        if (updatedGame.LaunchGameInHtml5 != gameBase.LaunchGameInHtml5)
                            domainGame.LaunchGameInHtml5 = updatedGame.LaunchGameInHtml5;
                        else
                            domainGame.LaunchGameInHtml5 = null;
                                                    
                        #endregion

                        if (!isExist)
                        {
                            query2.Insert(db, domainGame);
                            cga.BackupCasinoGame(CurrentUserSession.UserSessionID, CurrentUserSession.UserID, 0, DateTime.Now);
                        }
                        else
                        {
                            query2.Update(db, domainGame);
                            cga.BackupCasinoGame(CurrentUserSession.UserSessionID, CurrentUserSession.UserID, domainGame.ID, DateTime.Now);
                        }
                    } // else

                    db.CommitTransaction();

                    //CacheManager.ClearCache(Constant.GameListCachePrefix);
                    //CacheManager.ClearCache(Constant.DomainGamesCachePrefix);
                    //CacheManager.ClearCache(Constant.DomainGamesCache2Prefix);
                    //CacheManager.ClearCache(Constant.TopWinnersCachePrefix);
                    CE.BackendThread.ScalableThumbnailProcessor.Begin();

                    string script = string.Format("<script language=\"javascript\" type=\"text/javascript\">top.onGameSaved(true, '', {0});</script>", (updatedGame.ID > 0).ToString().ToLowerInvariant());

                    return this.Content(script, "text/html");
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    db.RollbackTransaction();
                    string script = string.Format("<script language=\"javascript\" type=\"text/javascript\">top.onGameSaved(false, '{0}');</script>", ex.Message.SafeJavascriptStringEncode());
                    return this.Content(script, "text/html");
                } // try-catch
            }
        }



        private bool ThumbnailCallback()
        {
            return false;
        }




        #region Update Property
        [HttpPost]
        public JsonResult UpdateProperty(string ids, AvailableEditGameProperty property, object value, PropertyEditType? editType, bool setToDefault = false)
        {
            if (value != null)
            {
                try
                {
                    value = ((string[])value)[0];
                }
                catch { }
            }
            if (string.IsNullOrEmpty(ids) || (value == null && !setToDefault))
            {
                return this.Json(new { @success = false, @message = "Error, invalid argument!" });
            }
            string[] strIds = ids.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
            if (ids.Length == 0)
            {
                return this.Json(new { @success = false, @message = "Error, invalid argument!" });
            }

            if (!CheckedPermission(property))
            {
                return this.Json(new { @success = false, @message = string.Format("Error, you are not allowed to change [{0}]!", property.ToString()) });
            }

            bool updated = false;

            StringBuilder successedIds = new StringBuilder();
            bool isCommon = DomainManager.CurrentDomainID == Constant.SystemDomainID;
            long id = 0;
            foreach (string strId in strIds)
            {
                if (long.TryParse(strId, out id))
                {
                    if (InternalUpdateProperty(id, property, value, isCommon, editType.HasValue ? editType.Value : PropertyEditType.Add, setToDefault))
                    {
                        updated = true;
                        successedIds.AppendFormat(" {0},", id);
                    }
                }
            }

            if (updated)
            {
                CacheManager.ClearCache(Constant.GameListCachePrefix);
                CacheManager.ClearCache(Constant.DomainGamesCachePrefix);
                CacheManager.ClearCache(Constant.DomainGamesCache2Prefix);
                CacheManager.ClearCache(Constant.TopWinnersCachePrefix);

                return this.Json(new { @success = true, @successedIds = string.Format("[{0}]", successedIds.ToString().TrimEnd(new char[] { ',' })) });
            }

            return this.Json(new { @success = false, @error = "operation failed!" });
        }

        public bool CheckedPermission(AvailableEditGameProperty property)
        {
            if (!CurrentUserSession.IsAuthenticated)
                return false;

            switch (property)
            {

                case AvailableEditGameProperty.Enabled:

                case AvailableEditGameProperty.Width:
                case AvailableEditGameProperty.Height:
                case AvailableEditGameProperty.FPP:
                case AvailableEditGameProperty.BonusContribution:
                case AvailableEditGameProperty.PopularityCoefficient:
                case AvailableEditGameProperty.NewGame:
                case AvailableEditGameProperty.NewGameExpirationDate:
                case AvailableEditGameProperty.Tags:
                case AvailableEditGameProperty.JackpotType:
                case AvailableEditGameProperty.InvoicingGroup:
                case AvailableEditGameProperty.ReportingCategory:
                case AvailableEditGameProperty.ExcludeFromBonuses:
                case AvailableEditGameProperty.LaunchGameInHtml5:
                case AvailableEditGameProperty.AgeLimit:
                    {
                        return true;
                    }
                case AvailableEditGameProperty.FunMode:
                case AvailableEditGameProperty.RealMode:
                case AvailableEditGameProperty.AnonymousFunMode:
                case AvailableEditGameProperty.License:
                case AvailableEditGameProperty.OpVisible:
                case AvailableEditGameProperty.ExcludeFromBonuses_EditableByOperator:
                case AvailableEditGameProperty.SupportFreeSpinBonus:
                    {
                        if (CurrentUserSession.UserDomainID == Constant.SystemDomainID)
                            return true;
                        else
                            return false;
                    }
            }

            return false;
        }

        private bool InternalUpdateProperty(long id, AvailableEditGameProperty property, object value, bool updatingBase, PropertyEditType editType, bool setToDefault)
        {
            if (updatingBase && setToDefault)
                return false;
            bool succeed = false;
            using (DbManager db = new DbManager())
            {
                db.BeginTransaction();
                try
                {
                    CasinoGameAccessor cga = CasinoGameAccessor.CreateInstance<CasinoGameAccessor>(db);
                    SqlQuery<ceCasinoGameBase> query = new SqlQuery<ceCasinoGameBase>(db);
                    ceCasinoGameBase gameBase = null;
                    ceCasinoGame gameDomain = null;

                    if (id > 0)
                    {
                        gameBase = query.SelectByKey(id);
                        if (gameBase != null)
                        {
                            string column = string.Empty;
                            object defaultValue = null;
                            bool useBaseValueAsDefault = false;

                            if (string.IsNullOrWhiteSpace(gameBase.Slug))
                                gameBase.Slug = null;

                            if (!updatingBase)
                                gameDomain = cga.QueryDomainGame(DomainManager.CurrentDomainID, id);

                            bool isExist = gameDomain != null;

                            #region Resolve and assignment property
                            DateTime tempDateTime;
                            decimal tempDecimal;
                            int tempInt;
                            bool tempBool;
                            string tempString;
                            LicenseType tempLicense;

                            column = property.ToString();

                            bool valueVerified = setToDefault;
                            bool changed = true;
                            bool valueResolved = false;
                            switch (property)
                            {
                                #region bool properies
                                case AvailableEditGameProperty.Enabled:
                                case AvailableEditGameProperty.AnonymousFunMode:
                                case AvailableEditGameProperty.FunMode:
                                case AvailableEditGameProperty.RealMode:
                                case AvailableEditGameProperty.NewGame:
                                case AvailableEditGameProperty.OpVisible:
                                case AvailableEditGameProperty.ExcludeFromBonuses:
                                case AvailableEditGameProperty.ExcludeFromBonuses_EditableByOperator:
                                case AvailableEditGameProperty.SupportFreeSpinBonus:
                                case AvailableEditGameProperty.LaunchGameInHtml5:
                                case AvailableEditGameProperty.AgeLimit:
                                    useBaseValueAsDefault = true;
                                    if (!setToDefault)
                                    {
                                        if (bool.TryParse(value as string, out tempBool))
                                        {
                                            valueVerified = true;
                                            value = tempBool;
                                        }
                                    }
                                    break;
                                #endregion bool properies
                                case AvailableEditGameProperty.NewGameExpirationDate:
                                    if (!setToDefault)
                                    {
                                        if (DateTime.TryParse(value as string, out tempDateTime))
                                        {
                                            valueVerified = true;
                                            value = tempDateTime;
                                            defaultValue = null;
                                        }
                                    }

                                    break;
                                case AvailableEditGameProperty.License:
                                    if (!setToDefault)
                                    {
                                        if (Enum.TryParse(value as string, out tempLicense))
                                        {
                                            valueVerified = true;
                                            value = tempLicense;
                                            defaultValue = null;
                                        }
                                    }

                                    break;

                                case AvailableEditGameProperty.JackpotType:
                                    if (!setToDefault)
                                    {
                                        CE.db.JackpotType tempJackpot;
                                        if (Enum.TryParse(value as string, out tempJackpot))
                                        {
                                            valueVerified = true;
                                            value = tempJackpot;
                                            defaultValue = null;
                                        }
                                    }

                                    break;
                                #region digit properies
                                case AvailableEditGameProperty.Height:
                                case AvailableEditGameProperty.Width:
                                    if (!setToDefault)
                                    {
                                        if (int.TryParse(value as string, out tempInt))
                                        {
                                            valueVerified = true;
                                            value = tempInt;
                                            defaultValue = null;
                                        }
                                    }

                                    break;
                                case AvailableEditGameProperty.FPP:
                                case AvailableEditGameProperty.BonusContribution:
                                    if (!setToDefault)
                                    {
                                        if (decimal.TryParse(value as string, out tempDecimal))
                                        {
                                            valueVerified = true;
                                            tempDecimal /= 100M;
                                            value = tempDecimal;
                                            defaultValue = null;
                                        }
                                    }

                                    break;
                                case AvailableEditGameProperty.PopularityCoefficient:
                                    if (!setToDefault)
                                    {
                                        if (decimal.TryParse(value as string, out tempDecimal))
                                        {
                                            valueVerified = true;
                                            value = tempDecimal;
                                            defaultValue = null;
                                        }
                                    }

                                    break;
                                #endregion digit properies

                                case AvailableEditGameProperty.Tags:
                                    valueResolved = true;
                                    if (setToDefault)
                                    {
                                        value = null;
                                    }
                                    else
                                    {
                                        tempString = value as string;
                                        if (!string.IsNullOrWhiteSpace(tempString))
                                        {
                                            value = ResolveTags(updatingBase, gameBase.Tags, gameDomain == null ? null : gameDomain.Tags, tempString, out changed, editType);
                                        }
                                    }

                                    break;
                                default:
                                    column = null;
                                    changed = false;
                                    break;
                            }

                            if (!valueResolved && !string.IsNullOrWhiteSpace(column))
                            {
                                value = ResolveValue(updatingBase, setToDefault, gameBase, gameDomain, column, value, defaultValue, useBaseValueAsDefault, out changed);
                            }
                            #endregion Resolve and assignment property

                            if (changed)
                            {
                                succeed = true;
                                if (updatingBase)
                                {
                                    CasinoGameAccessor.UpdateGameBaseProperty(db, column, value, gameBase.ID);
                                    cga.BackupCasinoGameBase(CurrentUserSession.UserSessionID, CurrentUserSession.UserID, gameBase.ID, DateTime.Now);
                                }
                                else
                                {
                                    if (isExist)
                                    {
                                        CasinoGameAccessor.UpdateGameProperty(db, column, value, gameDomain.ID);
                                        cga.BackupCasinoGame(CurrentUserSession.UserSessionID, CurrentUserSession.UserID, gameDomain.ID, DateTime.Now);
                                    }
                                    else
                                    {
                                        CasinoGameAccessor.InsertNewGameWithSpecificProperty(db
                                            , DomainManager.CurrentDomainID
                                            , gameBase.ID
                                            , CurrentUserSession.SessionID
                                            , CurrentUserSession.UserID
                                            , column
                                            , value
                                            , gameBase.Enabled
                                            , gameBase.OpVisible
                                            );
                                        cga.BackupCasinoGame(CurrentUserSession.UserSessionID, CurrentUserSession.UserID, 0, DateTime.Now);
                                    }
                                }
                            }
                        }
                    }

                    db.CommitTransaction();

                    return succeed;
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    db.RollbackTransaction();
                }
            }
            return false;
        }

        private object ResolveValue(bool updatingBase, bool setToDefaultValue, ceCasinoGameBase gameBase, ceCasinoGame gameDomain, string column, object value, object defaultValue, bool useBaseValueAsDefault, out bool changed, PropertyEditType editType = PropertyEditType.Override)
        {
            changed = false;

            if (CeCasinoGameBaseProperties == null)
            {
                Type typeGameBase = typeof(ceCasinoGameBase);
                CeCasinoGameBaseProperties = typeGameBase.GetProperties(BindingFlags.Instance | BindingFlags.DeclaredOnly | BindingFlags.Public);
            }
            if (CeCasinoGameDomainProperties == null)
            {
                Type typeGameDomain = typeof(ceCasinoGame);
                CeCasinoGameDomainProperties = typeGameDomain.GetProperties(BindingFlags.Instance | BindingFlags.DeclaredOnly | BindingFlags.Public);
            }

            PropertyInfo propertyGameBase = CeCasinoGameBaseProperties.FirstOrDefault(f => f.Name.Equals(column));
            if (propertyGameBase != null)
            {
                if (updatingBase)
                {
                    object sourcesValue = propertyGameBase.GetValue(gameBase, null);
                    if (sourcesValue == null || !sourcesValue.ToString().Equals(value.ToString(), StringComparison.OrdinalIgnoreCase))
                        changed = true;
                }
                else
                {
                    PropertyInfo propertyGameDomain = CeCasinoGameDomainProperties.FirstOrDefault(f => f.Name.Equals(column));
                    if (propertyGameDomain != null)
                    {
                        object sourcesValue = propertyGameBase.GetValue(gameBase, null);
                        if (setToDefaultValue)
                        {
                            value = sourcesValue;
                            changed = true;
                        }
                        else if (sourcesValue != null && sourcesValue.ToString().Equals(value.ToString(), StringComparison.OrdinalIgnoreCase))
                        {
                            value = useBaseValueAsDefault ? sourcesValue : defaultValue;
                            changed = true;
                        }
                        else
                        {
                            if (gameDomain != null)
                            {
                                sourcesValue = propertyGameDomain.GetValue(gameDomain, null);
                                if (sourcesValue == null || !sourcesValue.ToString().Equals(value.ToString(), StringComparison.OrdinalIgnoreCase))
                                    changed = true;
                            }
                            else
                                changed = true;
                        }
                    }
                }
            }
            return value;
        }
        private string ResolveTags(bool updatingBase, string baseTags, string domainTags, string value, out bool changed, PropertyEditType editType)
        {
            changed = false;

            #region function ResolveTags
            Func<string, string, string> funcResolveTags = (strGameTags, strUpdateTags) =>
            {
                if (!string.IsNullOrWhiteSpace(strGameTags) && !string.IsNullOrWhiteSpace(strUpdateTags))
                {
                    string[] gameTags = strGameTags.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                    if (gameTags != null && gameTags.Length > 0)
                    {
                        string[] updateTags = strUpdateTags.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                        if (updateTags != null && updateTags.Length > 0)
                        {
                            string tempTags = "";
                            int i = 0;
                            foreach (string tag in gameTags)
                            {
                                if (!updateTags.Contains(tag))
                                {
                                    tempTags = string.Format("{0},{1}", tempTags, tag);
                                    i++;
                                }
                            }
                            if (i != gameTags.Length)
                            {
                                return tempTags + ",";
                            }
                        }
                    }
                }
                return strGameTags;
            };
            #endregion function ResolveTags

            switch (editType)
            {
                case PropertyEditType.Override:
                    changed = updatingBase ? (baseTags != value) : (domainTags != value);
                    break;
                case PropertyEditType.Add:
                    value = string.Format("{0},{1}", (updatingBase ? baseTags == null ? string.Empty : baseTags.TrimEnd(new char[] { ',' }) : domainTags == null ? string.Empty : domainTags.TrimEnd(new char[] { ',' })), value.TrimStart(new char[] { ',' }));
                    changed = true;
                    break;
                case PropertyEditType.Delete:
                    value = funcResolveTags(updatingBase ? baseTags : domainTags == null ? baseTags : domainTags, value);
                    changed = updatingBase ? (baseTags != value) : (domainTags != value);
                    break;
            }

            return value;
        }
        #endregion Update Property



        [HttpGet]
        public JsonResult GetNetEntGameInfo(string gameID)
        {
            using (GamMatrixClient client = new GamMatrixClient())
            {
                NetEntAPIRequest request = new NetEntAPIRequest()
                {
                    GetGameInfo = true,
                    GetGameInfoGameID = gameID,
                    GetGameInfoLanguage = "en",
                };
                request = client.SingleRequest<NetEntAPIRequest>(DomainManager.CurrentDomainID, request);

                Dictionary<string, string> dic = new Dictionary<string, string>();
                for (int i = 0; i < request.GetGameInfoResponse.Count - 1; i += 2)
                {
                    dic.Add(request.GetGameInfoResponse[i], request.GetGameInfoResponse[i + 1]);
                }

                return this.Json(new { @success = true, @data = dic }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpGet]
        public JsonResult NotifyChanges()
        {
            //MetadataFileCache.ClearCache(DomainManager.CurrentDomainID);

            //CacheManager.ClearCache(Constant.LiveCasinoTableListCachePrefix);
            //CacheManager.ClearCache(Constant.GameListCachePrefix);
            //CacheManager.ClearCache(Constant.DomainGamesCachePrefix);
            //CacheManager.ClearCache(Constant.DomainGamesCache2Prefix);
            //CacheManager.ClearCache(Constant.TopWinnersCachePrefix);

            //NetEntAPI.LiveCasinoTable.ClearCache(DomainManager.CurrentDomainID);

            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            var task1 = Task.Factory.StartNew(() =>
            {
                GamMatrixClient.NotifyGmCoreConfigurationChanged();
            });

            long domainID = DomainManager.CurrentDomainID;
            var task2 = Task.Factory.StartNew(() =>
            {
                CE.Integration.Metadata.Notifier.Send(domainID);
            });

            string[] cachePrefixKeys = new string[]
            {
                MetadataFileCache.GetCachePrefixKey(DomainManager.CurrentDomainID),

                Constant.LiveCasinoTableListCachePrefix,
                Constant.GameListCachePrefix,
                Constant.DomainGamesCachePrefix,
                Constant.DomainGamesCache2Prefix,
                Constant.TopWinnersCachePrefix,

                NetEntAPI.LiveCasinoTable.GetCachePrefixKey(DomainManager.CurrentDomainID),
            };
            CacheManager.ClearCache(cachePrefixKeys);

            string result = CE.BackendThread.ChangeNotifier.SendToAll(CE.BackendThread.ChangeNotifier.ChangeType.GameList, DomainManager.CurrentDomainID);

            Task.WaitAll(new Task[] { task1, task2 });

            Logger.Information(string.Format("GameList Changed Notification Sent! \n {0}", result));

            return this.Json(new { @success = true, @result = result }, JsonRequestBehavior.AllowGet);
        }

        #region translation
        public ActionResult EditGameTranslation(long? id, string propertyName)
        {
            ceCasinoGameBaseEx game = null;
            if (id.HasValue && id.Value > 0)
            {
                game = CasinoGameAccessor.GetDomainGame(DomainManager.CurrentDomainID, id.Value);
            }
            if (game == null)
            {
                return RedirectToAction("Index");
            }
            game.FPP = decimal.Round(100.0M * game.FPP, 3);
            game.TheoreticalPayOut = decimal.Round(100.0M * game.TheoreticalPayOut, 3);
            game.JackpotContribution = decimal.Round(100.0M * game.JackpotContribution, 3);
            game.ThirdPartyFee = decimal.Round(100.0M * game.ThirdPartyFee, 3);
            game.BonusContribution = decimal.Round(100.0M * game.BonusContribution, 3);
            game.PopularityCoefficient = game.PopularityCoefficient * 100 / 100;

            var domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == DomainManager.CurrentDomainID);
            if (domain == null && DomainManager.GetSysDomain().DomainID == DomainManager.CurrentDomainID)
                domain = DomainManager.GetSysDomain();

            if (domain == null)
                throw new Exception("domain can't be found");

            if (propertyName != CasinoGameMgr.METADATA_DESCRIPTION)
                throw new Exception(string.Format("unexpected propertyName [{0}]", propertyName));

            this.ViewData["ShowHeader"] = false;
            this.ViewData["GameTranslations"] = GetGameTranslations(domain, game, propertyName);
            this.ViewData["PropertyName"] = propertyName;

            return View("GameTranslationEditDialog", game);
        }

        [ValidateInput(false)]
        public ActionResult SaveGameTranslation(ceCasinoGameBase game, string propertyName, string language, string translation)
        {
            try
            {
                var domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == DomainManager.CurrentDomainID);
                if (domain == null && DomainManager.GetSysDomain().DomainID == DomainManager.CurrentDomainID)
                    domain = DomainManager.GetSysDomain();

                if (domain == null)
                    throw new Exception("domain can't be found");

                if (propertyName != CasinoGameMgr.METADATA_DESCRIPTION)
                    throw new Exception(string.Format("unexpected propertyName [{0}]", propertyName));

                var translations = new Dictionary<string, string>();
                translations.Add(language, translation);

                string error;
                if (!new CasinoGameMgr(propertyName).Update(domain, game.ID, translations, out error))
                    throw new Exception(error);

                return Json(new
                {
                    @success = true,
                    @data = GetMetadataGameInformations(domain, game)
                }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                return Json(new
                {
                    @success = false,
                    @error = ex.Message
                }, JsonRequestBehavior.AllowGet);
            }
        }

        public ActionResult DeleteGameTranslation(ceCasinoGameBase game, string propertyName, string language)
        {
            try
            {
                var domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == DomainManager.CurrentDomainID);
                if (domain == null && DomainManager.GetSysDomain().DomainID == DomainManager.CurrentDomainID)
                    domain = DomainManager.GetSysDomain();

                if (domain == null)
                    throw new Exception("domain can't be found");

                if (propertyName != CasinoGameMgr.METADATA_DESCRIPTION)
                    throw new Exception(string.Format("unexpected propertyName [{0}]", propertyName));

                var languages = new List<string>();
                languages.Add(language);

                string error;
                if (!new CasinoGameMgr(propertyName).Delete(domain, game.ID, languages, out error))
                    throw new Exception(error);

                return Json(new
                {
                    @success = true,
                    @data = GetMetadataGameInformations(domain, game)
                }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                return Json(new
                {
                    @success = false,
                    @error = ex.Message
                }, JsonRequestBehavior.AllowGet);
            }
        }

        private string GetGameTranslations(ceDomainConfig domain, ceCasinoGameBase game, string propertyName)
        {
            var translations = new CasinoGameMgr(propertyName).Get(domain, game.ID);

            using (var sw = new StringWriter())
            using (var writer = new JsonTextWriter(sw))
            {
                writer.WriteStartArray();
                foreach (var translation in translations)
                {
                    writer.WriteStartObject();

                    writer.WritePropertyName("name", true);
                    writer.WriteValue(translation.Name);

                    writer.WritePropertyName("code", true);
                    writer.WriteValue(translation.Code);

                    writer.WritePropertyName("content", true);
                    writer.WriteValue(translation.Content);

                    writer.WritePropertyName("status", true);
                    if (translation.HasContent)
                    {
                        if (translation.IsInherited)
                            writer.WriteValue("inherit");
                        else
                            writer.WriteValue("normal");
                    }
                    else
                    {
                        writer.WriteValue("none");
                    }

                    writer.WritePropertyName("name", true);
                    writer.WriteValue(translation.Name);

                    writer.WriteEndObject();
                }
                writer.WriteEndArray();

                return sw.ToString();
            }
        }
        #endregion

        #region game information
        public ActionResult EditGameInformation(long? id)
        {
            ceCasinoGameBaseEx game = null;
            if (id.HasValue && id.Value > 0)
            {
                game = CasinoGameAccessor.GetDomainGame(DomainManager.CurrentDomainID, id.Value);
            }
            if (game == null)
            {
                return RedirectToAction("Index");
            }
            game.FPP = decimal.Round(100.0M * game.FPP, 3);
            game.TheoreticalPayOut = decimal.Round(100.0M * game.TheoreticalPayOut, 3);
            game.JackpotContribution = decimal.Round(100.0M * game.JackpotContribution, 3);
            game.ThirdPartyFee = decimal.Round(100.0M * game.ThirdPartyFee, 3);
            game.BonusContribution = decimal.Round(100.0M * game.BonusContribution, 3);
            game.PopularityCoefficient = game.PopularityCoefficient * 100 / 100;

            var domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == DomainManager.CurrentDomainID);
            if (domain == null && DomainManager.GetSysDomain().DomainID == DomainManager.CurrentDomainID)
                domain = DomainManager.GetSysDomain();

            if (domain == null)
                throw new Exception("domain can't be found");

            this.ViewData["ShowHeader"] = false;
            this.ViewData["MetadataGameInformations"] = GetMetadataGameInformations(domain, game);

            return View("GameInformationEditDialog", game);
        }

        [ValidateInput(false)]
        public ActionResult SaveGameInformation(ceCasinoGameBase game, string language, string translation)
        {
            try
            {
                var domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == DomainManager.CurrentDomainID);
                if (domain == null && DomainManager.GetSysDomain().DomainID == DomainManager.CurrentDomainID)
                    domain = DomainManager.GetSysDomain();

                if (domain == null)
                    throw new Exception("domain can't be found");

                var translations = new Dictionary<string, string>();
                translations.Add(language, translation);

                string error;
                if (!new CasinoGameMgr(CasinoGameMgr.METADATA_GAME_INFORMATION).Update(domain, game.ID, translations, out error))
                    throw new Exception(error);

                return Json(new
                {
                    @success = true,
                    @data = GetMetadataGameInformations(domain, game)
                }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                return Json(new
                {
                    @success = false,
                    @error = ex.Message
                }, JsonRequestBehavior.AllowGet);
            }
        }

        public ActionResult DeleteGameInformation(ceCasinoGameBase game, string language)
        {
            try
            {
                var domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == DomainManager.CurrentDomainID);
                if (domain == null && DomainManager.GetSysDomain().DomainID == DomainManager.CurrentDomainID)
                    domain = DomainManager.GetSysDomain();

                if (domain == null)
                    throw new Exception("domain can't be found");

                var languages = new List<string>();
                languages.Add(language);

                string error;
                if (!new CasinoGameMgr(CasinoGameMgr.METADATA_GAME_INFORMATION).Delete(domain, game.ID, languages, out error))
                    throw new Exception(error);

                return Json(new
                {
                    @success = true,
                    @data = GetMetadataGameInformations(domain, game)
                }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                return Json(new
                {
                    @success = false,
                    @error = ex.Message
                }, JsonRequestBehavior.AllowGet);
            }
        }

        private string GetMetadataGameInformations(ceDomainConfig domain, ceCasinoGameBase game)
        {
            var translations = new CasinoGameMgr(CasinoGameMgr.METADATA_GAME_INFORMATION).Get(domain, game.ID);

            using (var sw = new StringWriter())
            using (var writer = new JsonTextWriter(sw))
            {
                writer.WriteStartArray();
                foreach (var translation in translations)
                {
                    writer.WriteStartObject();

                    writer.WritePropertyName("name", true);
                    writer.WriteValue(translation.Name);

                    writer.WritePropertyName("code", true);
                    writer.WriteValue(translation.Code);

                    writer.WritePropertyName("content", true);
                    writer.WriteValue(translation.Content);

                    writer.WritePropertyName("status", true);
                    if (translation.HasContent)
                    {
                        if (translation.IsInherited)
                            writer.WriteValue("inherit");
                        else
                            writer.WriteValue("normal");
                    }
                    else
                    {
                        writer.WriteValue("none");
                    }

                    writer.WritePropertyName("name", true);
                    writer.WriteValue(translation.Name);

                    writer.WriteEndObject();
                }
                writer.WriteEndArray();

                return sw.ToString();
            }
        }
        #endregion

        public ActionResult AddImage(HttpPostedFileBase imageFile)
        {
            try
            {
                string path;
                string imageFileName;
                byte[] imageBuffer;
                if (!ImageAsset.ParseImage(imageFile, out imageFileName, out imageBuffer))
                    throw new Exception("Unknown error");

                path = ImageAsset.GetImageFtpFilePath(imageFileName);
                FTP.UploadFile(DomainManager.CurrentDomainID, path, imageBuffer);

                return Json(new
                {
                    @success = true,
                    @link = ConfigurationManager.AppSettings["StaticFileHost.WebUrl"] + path
                }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                return Json(new
                {
                    @success = false,
                    @error = ex.Message
                }, JsonRequestBehavior.AllowGet);
            }
        }

        [ValidateInput(false)]
        public ActionResult Transfer(string text)
        {
            var md = new MarkdownDeep.Markdown
            {
                SafeMode = false,
                ExtraMode = true,
                AutoHeadingIDs = false,
                MarkdownInHtml = true,
                NewWindowForExternalLinks = true
            };
            var html = md.Transform(text.Replace("<", "&lt;").Replace(">", "&gt;"));
            return Json(new
            {
                html = html,
            }, JsonRequestBehavior.AllowGet);
        }


        public ActionResult RevertOrDeleteGame(long id)
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            using (DbManager db = new DbManager())
            {
                db.BeginTransaction();
                try
                {
                    var cga = CasinoGameAccessor.CreateInstance<CasinoGameAccessor>(db);
                    if (DomainManager.CurrentDomainID != Constant.SystemDomainID)
                    {
                        //To Defaults
                        ceCasinoGame game = cga.QueryDomainGame(DomainManager.CurrentDomainID, id);
                        bool isExist = game != null;
                        if (!isExist)
                            return this.Json(new { success = false, error = "Game not found!" }, JsonRequestBehavior.AllowGet);

                        var query = new SqlQuery<ceCasinoGame>();
                        query.Delete(game);
                    }
                    else
                    {
                        //Delete Game
                        ceCasinoGameBase game = CasinoGameAccessor.GetDomainGame(DomainManager.CurrentDomainID, id);
                        bool isExist = game != null;
                        if (!isExist)
                            return this.Json(new { success = false, error = "Game not found!" }, JsonRequestBehavior.AllowGet);

                        var gameOverrides = CasinoGameAccessor.GetGameOverrides(id);
                        if (gameOverrides.Count > 0)
                            return this.Json(new { success = false, error = "Game has " + gameOverrides.Count + " overrides. Please revert those to Defaults first!" }, JsonRequestBehavior.AllowGet);

                        var query = new SqlQuery<ceCasinoGameBase>();
                        query.Delete(game);
                    }

                    db.CommitTransaction();

                    return this.Json(new { success = true }, JsonRequestBehavior.AllowGet);
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    return this.Json(new {success = false, error = ex.Message}, JsonRequestBehavior.AllowGet);
                }
            }
        }

        [HttpGet]
        public ActionResult GetGamesListJson(string filteredVendorIDs)
        {
            var pageIndex = 1;
            var pageSize = 9999999;
            int totalCount = 0;

            var vendorStrings = filteredVendorIDs.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
            List<VendorID> vendorIDs = new List<VendorID>();
            foreach (var vendor in vendorStrings)
            {
                VendorID vendorId;
                Enum.TryParse(vendor, true, out vendorId);
                vendorIDs.Add(vendorId);
            }

            Dictionary<string, object> parameters = new Dictionary<string, object>();
            parameters.Add("VendorID", vendorIDs.ToArray());
            parameters.Add("Enabled", true);

            List<ceCasinoGameBase> games = CasinoGameAccessor.SearchGames(pageIndex, pageSize, Constant.SystemDomainID, parameters, out totalCount, true, CurrentUserSession.UserDomainID != Constant.SystemDomainID).ConvertAll(x => (ceCasinoGameBase)x);
            var selectedVendors = string.Join(",", filteredVendorIDs);
            return File(Encoding.UTF8.GetBytes(JsonConvert.SerializeObject(games)),
                 "text/plain",
                  string.Format("{0}_{1}.json.txt", DateTime.Now.ToShortDateString(), selectedVendors.Substring(0, Math.Min(50, selectedVendors.Length))));//"Export"));//
        }

        [HttpGet]
        public ActionResult UploadGamesJson()
        {
            return View();
        }

        [HttpPost]
        public ActionResult UploadGamesJson(HttpPostedFileBase file, string overrideExistingGames = "false")
        {
            var importedGames = new List<ceCasinoGameBase>();
            try
            {
                BinaryReader b = new BinaryReader(file.InputStream);
                byte[] binData = b.ReadBytes(file.ContentLength);
                string fileContents = Encoding.UTF8.GetString(binData);

                JsonConvert.PopulateObject(fileContents, importedGames);
            }
            catch (Exception)
            {
                return this.Json(new { @success = false, @message = "Import file contents are corrupted, import aborted!" }, JsonRequestBehavior.AllowGet);
            }
            
            if (importedGames.Count > 0)
            {
                var pageIndex = 1;
                var pageSize = 9999999;
                int totalCount = 0;
                var parameters = new Dictionary<string, object>();
                parameters.Add("VendorID", importedGames.Select(g => g.VendorID).Distinct().ToArray());
                parameters.Add("Enabled", true);

                List<ceCasinoGameBase> existingGames = CasinoGameAccessor.SearchGames(pageIndex, pageSize, Constant.SystemDomainID, parameters, out totalCount, true, CurrentUserSession.UserDomainID != Constant.SystemDomainID).ConvertAll(x => (ceCasinoGameBase)x);
                
                Func<ceCasinoGameBase, ceCasinoGameBase, bool> gamesAreEqual = delegate(ceCasinoGameBase local, ceCasinoGameBase imported)
                { return local.VendorID == imported.VendorID
                    && local.GameID == imported.GameID
                    && local.GameCode == imported.GameCode;
                };

                using (DbManager db = new DbManager())
                {
                    db.BeginTransaction();
                    try
                    {
                        var cga = CasinoGameAccessor.CreateInstance<CasinoGameAccessor>(db);
                        SqlQuery<ceCasinoGameBase> query = new SqlQuery<ceCasinoGameBase>(db);
                        int gamesInserted = 0;
                        int gamesToUpdate = 0;
                        int gamesUpdated = 0;

                        foreach (ceCasinoGameBase game in existingGames)
                        {
                            var importedGame = importedGames.FirstOrDefault(ig => gamesAreEqual(ig, game));
                            if (importedGame != null)
                            {
                                //overwrite existing game data with newly imported
                                if (overrideExistingGames == "true")
                                {
                                    importedGame.ID = game.ID;
                                    gamesUpdated += query.Update(db, importedGame);
                                    //cga.BackupCasinoGameBase(CurrentUserSession.UserSessionID, CurrentUserSession.UserID, game.ID, DateTime.Now);
                                }
                                importedGames.Remove(importedGame);
                                gamesToUpdate++;
                            }
                        }

                        foreach (ceCasinoGameBase importedGame in importedGames)
                        {
                            importedGame.ID = 0;
                            gamesInserted += query.Insert(importedGame);
                            //cga.BackupCasinoGameBase(CurrentUserSession.UserSessionID, CurrentUserSession.UserID, 0, DateTime.Now);
                        }

                        if (gamesUpdated != gamesToUpdate)
                            return this.Json(new { @success = false, @message = string.Format("Something went wrong with UPDATING EXISTING Games: imported {0} from {1} games", gamesUpdated, gamesToUpdate) }, JsonRequestBehavior.AllowGet);

                        if (gamesInserted != importedGames.Count)
                            return this.Json(new { @success = false, @message = string.Format("Something went wrong with INSERTING NEW Games: imported {0} from {1} games", gamesInserted, importedGames.Count) }, JsonRequestBehavior.AllowGet);

                        db.CommitTransaction();
                    }
                    catch (Exception ex)
                    {
                        db.RollbackTransaction();
                        return this.Json(new {@success = false, @message = ex.Message}, JsonRequestBehavior.AllowGet);
                    }
                }
                
            }
            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }

        private Dictionary<string, CasinoGameLimitAmount> ParseLimit()
        {
            Dictionary<string, CasinoGameLimitAmount> LimitAmounts = new Dictionary<string, CasinoGameLimitAmount>();
            decimal amount;
            CurrencyData[] currencies = GamMatrixClient.GetSupportedCurrencies();
            foreach (CurrencyData currency in currencies)
            {
                CasinoGameLimitAmount limitAmount = new CasinoGameLimitAmount();
                string key = string.Format("maxAmount_{0}", currency.ISO4217_Alpha);
                if (decimal.TryParse(Request.Form[key], out amount))
                {
                    if (amount == 0.00M) 
                    {
                        continue;
                    }
                    limitAmount.MaxAmount = amount;
                }

                key = string.Format("minAmount_{0}", currency.ISO4217_Alpha);
                if (decimal.TryParse(Request.Form[key], out amount))
                    limitAmount.MinAmount = amount;

                LimitAmounts.Add(currency.ISO4217_Alpha, limitAmount);
            }

            return LimitAmounts;
        }

        private string RemoveDuplicateData(string oldData)
        {
            if(!string.IsNullOrWhiteSpace(oldData))
            {
                List<string> oldList = new List<string>(oldData.Split(new string[] { "," }, StringSplitOptions.RemoveEmptyEntries));
                var newList = (from a in oldList select a).Distinct().OrderBy(g => g);
                return string.Join(",", newList.ToArray());
            }
            else
            {
                return null;
            }
        }
    }
}
