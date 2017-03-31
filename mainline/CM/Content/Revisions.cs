using System;
using System.IO;
using System.Web.Hosting;
using BLToolkit.DataAccess;
using CM.db;
using CM.db.Accessor;
using CM.State;

namespace CM.Content
{
    public static class Revisions
    {
        public static string GetBaseDirectory()
        {
            string path = HostingEnvironment.MapPath("~/revisions/");
            if (!Directory.Exists(path))
                Directory.CreateDirectory(path);
            return path.TrimEnd('\\');
        }

        public static string GetLocalPath(string filePath)
        {
            return GetBaseDirectory() + filePath;
        }

        public static string GetNewFilePath(out string filePath)
        {
            string baseDir = GetBaseDirectory();
            filePath = string.Format("\\{0:0000}\\", DateTime.Now.Year);
            if (!Directory.Exists(baseDir + filePath))
                Directory.CreateDirectory(baseDir + filePath);

            filePath += string.Format("{0:00}\\", DateTime.Now.Month);
            if (!Directory.Exists(baseDir + filePath))
                Directory.CreateDirectory(baseDir + filePath);

            filePath += string.Format("{0:00}\\", DateTime.Now.Day);
            if (!Directory.Exists(baseDir + filePath))
                Directory.CreateDirectory(baseDir + filePath);

            filePath += string.Format("{0}.bak", Guid.NewGuid().ToString("N"));
            return baseDir + filePath;
        }

        public static string GetRevisionFilePath(int revisionID)
        {
            RevisionAccessor ra = DataAccessor.CreateInstance<RevisionAccessor>();
            cmRevision revision = ra.GetByID(revisionID);
            if (revision != null)
                return GetBaseDirectory() + revision.FilePath;

            return null;
        }

        public static void RollbackRevision(int revisionID, int userID = 0)
        {
            if (userID == 0)
                userID = CustomProfile.Current.UserID;

            RevisionAccessor ra = DataAccessor.CreateInstance<RevisionAccessor>();
            cmRevision revision = ra.GetByID(revisionID);

            string file = null;
            if (revision != null)
                file = GetBaseDirectory() + revision.FilePath;

            if (string.IsNullOrEmpty(file) || !File.Exists(file))
                throw new Exception("Error, can't find this revision.");

            if (revision.RelativePath.StartsWith("/.config/", StringComparison.InvariantCultureIgnoreCase))
                throw new Exception("Error, can't rollback this revision.");

            string realPath = HostingEnvironment.MapPath(string.Format("~/Views/{0}{1}", revision.DomainDistinctName, revision.RelativePath));

            SqlQuery<cmRevision> query = new SqlQuery<cmRevision>();

            string filePath;
            string localFile = Revisions.GetNewFilePath(out filePath);

            cmRevision newRevision = new cmRevision();
            newRevision.Comments = string.Format("Rollback to Rev.{0}", revisionID);
            newRevision.SiteID = revision.SiteID;
            newRevision.FilePath = filePath;
            newRevision.Ins = DateTime.Now;
            newRevision.RelativePath = revision.RelativePath;
            newRevision.UserID = userID;
            query.Insert(newRevision);

            global::System.IO.File.Copy(file, realPath, true);
            global::System.IO.File.Copy(file, localFile, true);
        }

        public static cmRevision GetRevisionByID(int revisionID)
        {
            RevisionAccessor ra = DataAccessor.CreateInstance<RevisionAccessor>();
            cmRevision revision = ra.GetByID(revisionID);
            return revision;
        }

        public static void BackupIfNotExists<T>(cmSite site, T t, string relativePath, string name, bool nameAsComments = false)
        {
            // if last revision not exist, backup first
            RevisionAccessor ra = DataAccessor.CreateInstance<RevisionAccessor>();
            cmRevision revision = ra.GetLastRevision(site.ID, relativePath);
            if (revision == null || !File.Exists(Revisions.GetLocalPath(revision.FilePath)))
            {
                string localFile, filePath;
                localFile = Revisions.GetNewFilePath(out filePath);
                ObjectHelper.XmlSerialize<T>(t, localFile);

                SqlQuery<cmRevision> query = new SqlQuery<cmRevision>();

                revision = new cmRevision();
                if (nameAsComments)
                    revision.Comments = name;
                else
                    revision.Comments = string.Format("No revision found for [{0}], make a backup.", name);
                revision.SiteID = site.ID;
                revision.FilePath = filePath;
                revision.Ins = DateTime.Now;
                revision.RelativePath = relativePath;
                revision.UserID = CustomProfile.Current.UserID;
                query.Insert(revision);
            }
        }

        public static void BackupIfNotExists(cmSite site, string path, string relativePath, string name, bool nameAsComments = false)
        {
            if (File.Exists(path))
            {
                // if last revision not exist, backup first
                RevisionAccessor ra = DataAccessor.CreateInstance<RevisionAccessor>();
                cmRevision revision = ra.GetLastRevision(site.ID, relativePath);
                if (revision == null || !File.Exists(Revisions.GetLocalPath(revision.FilePath)))
                {
                    SqlQuery<cmRevision> query = new SqlQuery<cmRevision>();

                    string localFile, filePath;
                    localFile = Revisions.GetNewFilePath(out filePath);
                    File.Copy(path, localFile);

                    revision = new cmRevision();
                    if (nameAsComments)
                        revision.Comments = name;
                    else
                        revision.Comments = string.Format("No revision found for [{0}], make a backup.", name);
                    revision.SiteID = site.ID;
                    revision.FilePath = filePath;
                    revision.Ins = DateTime.Now;
                    revision.RelativePath = relativePath;
                    revision.UserID = CustomProfile.Current.UserID;
                    query.Insert(revision);
                }
            }
        }

        public static void Backup<T>(cmSite site, T t, string relativePath, string name, bool nameAsComments = false)
        {
            string localFile, filePath;

            SqlQuery<cmRevision> query = new SqlQuery<cmRevision>();

            // copy the file to backup
            localFile = Revisions.GetNewFilePath(out filePath);
            ObjectHelper.XmlSerialize<T>(t, localFile);

            // save to cmRevision
            cmRevision revision = new cmRevision();
            if (nameAsComments)
                revision.Comments = name;
            else
                revision.Comments = string.Format("Update the config for [{0}]", name);
            revision.SiteID = site.ID;
            revision.FilePath = filePath;
            revision.Ins = DateTime.Now;
            revision.RelativePath = relativePath;
            revision.UserID = CustomProfile.Current.UserID;
            query.Insert(revision);
        }

        public static void Backup(cmSite site, string path, string relativePath, string name, bool nameAsComments = false)
        {
            string localFile, filePath;

            SqlQuery<cmRevision> query = new SqlQuery<cmRevision>();

            // copy the file to backup
            localFile = Revisions.GetNewFilePath(out filePath);
            File.Copy(path, localFile);

            // save to cmRevision
            cmRevision revision = new cmRevision();
            if (nameAsComments)
                revision.Comments = name;
            else
                revision.Comments = string.Format("Update the config for [{0}]", name);
            revision.SiteID = site.ID;
            revision.FilePath = filePath;
            revision.Ins = DateTime.Now;
            revision.RelativePath = relativePath;
            revision.UserID = CustomProfile.Current.UserID;
            query.Insert(revision);
        }

        public static T TryToDeserialize<T>(cmRevision revision, T defaultValue)
        {
            return ObjectHelper.XmlDeserialize<T>(Revisions.GetBaseDirectory() + revision.FilePath, defaultValue);
        }

        public static void Create(cmSite site, string relativePath, string comments, string filePath)
        {
            SqlQuery<cmRevision> query = new SqlQuery<cmRevision>();

            var revision = new cmRevision();
            revision.Comments = comments;
            revision.SiteID = site.ID;
            revision.FilePath = filePath;
            revision.Ins = DateTime.Now;
            revision.RelativePath = relativePath;
            revision.UserID = CustomProfile.Current.UserID;
            query.Insert(revision);
        }

    }
}
