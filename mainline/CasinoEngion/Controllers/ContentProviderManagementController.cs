using System;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Mvc;
using BLToolkit.Data;
using BLToolkit.DataAccess;
using CE.db;
using CE.db.Accessor;
using CE.Utils;

namespace CasinoEngine.Controllers
{
    [SystemAuthorize]
    public class ContentProviderManagementController: Controller
    {
        public ActionResult Index()
        {

            return View();
        }

        public ActionResult ProviderList()
        {
            return View("ProviderList");
        }

        public ActionResult ProviderEditorDialog(int? id)
        {
            ceContentProviderBase provider = new ceContentProviderBase();
            if (id.HasValue)
            {
                provider = ContentProviderAccessor.Get(id.Value, DomainManager.CurrentDomainID);
            }
            return View("ProviderEditorDialog", provider);
        }

        [HttpPost]
        public ContentResult Save(ceContentProviderBase updatedProvider
            , HttpPostedFileBase logoFile)
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            try
            {
                string logoImageFilePath = null;
                string imageFileName;
                byte[] imageBuffer;
                if (ImageAsset.ParseImage(logoFile, out imageFileName, out imageBuffer))
                {
                    logoImageFilePath = ImageAsset.GetImageFtpFilePath(imageFileName);
                    FTP.UploadFile(DomainManager.CurrentDomainID, logoImageFilePath, imageBuffer);
                }

                using (DbManager db = new DbManager())
                {
                    if (DomainManager.CurrentDomainID == Constant.SystemDomainID)
                    {
                        if (string.IsNullOrWhiteSpace(updatedProvider.Identifying))
                            throw new ArgumentNullException("Identifying");

                        if (string.IsNullOrWhiteSpace(updatedProvider.Name))
                            throw new ArgumentNullException("Name");

                        if (!string.IsNullOrWhiteSpace(updatedProvider.Name))
                        {
                            updatedProvider.Name = Regex.Replace(updatedProvider.Name, @"[^a-z_\-\d]", string.Empty, RegexOptions.CultureInvariant | RegexOptions.IgnoreCase | RegexOptions.ECMAScript| RegexOptions.Compiled);
                            if (Regex.IsMatch(updatedProvider.Name, "^(\\d+)$", RegexOptions.CultureInvariant| RegexOptions.Compiled))
                                throw new Exception("The name can not only contain digits.");
                        }

                        SqlQuery<ceContentProviderBase> query = new SqlQuery<ceContentProviderBase>(db);

                        ceContentProviderBase provider = null;

                        if (updatedProvider.ID > 0)
                            provider = query.SelectByKey(updatedProvider.ID);
                        if (provider == null)
                        {
                            provider = new ceContentProviderBase();
                            provider.Ins = DateTime.Now;
                            provider.Enabled = true;
                        }

                        bool changed = false;

                        if (string.IsNullOrWhiteSpace(provider.Identifying) && provider.Identifying != updatedProvider.Identifying)
                        {
                            provider.Identifying = updatedProvider.Identifying;
                            changed = true;
                        }

                        if (provider.Name != updatedProvider.Name)
                        {
                            provider.Name = updatedProvider.Name;
                            changed = true;
                        }

                        if (!string.IsNullOrWhiteSpace(logoImageFilePath))
                        {
                            if (provider.Logo != logoImageFilePath)
                            {
                                provider.Logo = logoImageFilePath;
                                changed = true;
                            }
                        }
                        if (provider.ID > 0)
                        {
                            if (changed)
                                query.Update(db, provider);
                        }
                        else
                        {
                            query.Insert(db, provider);
                        }
                    }
                    else if (updatedProvider.ID > 0)
                    {
                        SqlQuery<ceContentProviderBase> queryBase = new SqlQuery<ceContentProviderBase>(db);
                        ceContentProviderBase providerBase = queryBase.SelectByKey(updatedProvider.ID);

                        SqlQuery<ceContentProvider> query = new SqlQuery<ceContentProvider>(db);

                        ContentProviderAccessor cpa = ContentProviderAccessor.CreateInstance<ContentProviderAccessor>();
                        ceContentProvider provider = cpa.QueryDomainProvider(updatedProvider.ID, DomainManager.CurrentDomainID);

                        if (provider == null)
                        {
                            provider = new ceContentProvider();
                            provider.ContentProviderBaseID = providerBase.ID;
                            provider.Enabled = null;
                            provider.Ins = DateTime.Now;
                            provider.Logo = null;
                            provider.DomainID = DomainManager.CurrentDomainID;
                        }

                        bool changed = false;

                        if (!string.IsNullOrWhiteSpace(logoImageFilePath))
                        {
                            if (providerBase.Logo != updatedProvider.Logo)
                                provider.Logo = logoImageFilePath;
                            else
                                provider.Logo = null;

                            changed = true;
                        }

                        if (provider.ID > 0)
                        {
                            if (changed)
                            {
                                query.Update(db, provider);
                            }
                        }
                        else
                        {
                            query.Insert(db, provider);
                        }
                    }
                }


                string script = "<script language=\"javascript\" type=\"text/javascript\">top.onSaved(true, '');</script>";

                return this.Content(script, "text/html");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                string script = string.Format("<script language=\"javascript\" type=\"text/javascript\">top.onSaved(false, '{0}');</script>", ex.Message.SafeJavascriptStringEncode());
                return this.Content(script, "text/html");
            }
        }


        public JsonResult Enable(long[] providerIDs, bool enable)
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            try
            {
                if (!CurrentUserSession.IsSystemUser)
                    throw new CeException("You are not allowed to perform this operation.");

                SqlQuery<ceContentProviderBase> query1 = new SqlQuery<ceContentProviderBase>();
                SqlQuery<ceContentProvider> query2 = new SqlQuery<ceContentProvider>();
                ContentProviderAccessor cpa = ContentProviderAccessor.CreateInstance<ContentProviderAccessor>();

                foreach (int providerID in providerIDs)
                {
                    if (CurrentUserSession.IsSystemUser && DomainManager.CurrentDomainID == Constant.SystemDomainID)
                    {
                        ceContentProviderBase baseProvider = query1.SelectByKey(providerID);
                        baseProvider.Enabled = enable;
                        query1.Update(baseProvider);
                    }
                    else
                    {
                        ceContentProvider provider = cpa.QueryDomainProvider(providerID, DomainManager.CurrentDomainID);
                        if (provider == null)
                        {
                            provider = new ceContentProvider();
                            provider.DomainID = DomainManager.CurrentDomainID;
                            provider.ContentProviderBaseID = providerID;
                            provider.Logo = null;
                            provider.Ins = DateTime.Now;

                            provider.Enabled = enable;

                            query2.Insert(provider);
                        }
                        else
                        {
                            if (string.IsNullOrWhiteSpace(provider.Logo))
                                provider.Logo = null;


                            provider.Enabled = enable;
                            query2.Update(provider);
                        }
                    }
                }
                return this.Json(new { success = true }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { success = false, error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }
    }
}