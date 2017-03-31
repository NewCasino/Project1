using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Security.Cryptography;
using BLToolkit.Data;
using BLToolkit.DataAccess;
using CE.db;
using CE.db.Accessor;
using CE.Utils;

namespace CE.BackendThread
{
    public static class ScalableThumbnailProcessor
    {
        public static void Begin()
        {
            BackgroundThreadPool.QueueUserWorkItem( "ScalableThumbnailProcessor", ProcessScalableThumbnails, null);
        }

        private static ImageCodecInfo GetEncoder(ImageFormat format)
        {
            ImageCodecInfo[] codecs = ImageCodecInfo.GetImageDecoders();
            foreach (ImageCodecInfo codec in codecs)
            {
                if (codec.FormatID == format.Guid)
                {
                    return codec;
                }
            }
            return null;
        }

        private static void ProcessScalableThumbnails(object state)
        {
            try
            {
                List<ceScalableThumbnail> list = null;
                using (DbManager db = new DbManager())
                {
                    ScalableThumbnailAccessor sta = ScalableThumbnailAccessor.CreateInstance<ScalableThumbnailAccessor>(db);
                    list = sta.GetUnscaledThumbnail();

                    // queue the task in random order
                    Random r = new Random();
                    while (list.Count > 0)
                    {
                        int index = r.Next(list.Count - 1);

                        if (!string.IsNullOrEmpty(list[index].OrginalFileName))
                            ProcessScalableThumbnail(db, list[index]);
                        list.RemoveAt(index);
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }

            if (state == null)
                ProcessScalableThumbnails(typeof(ScalableThumbnailProcessor));
        }

        private static void ProcessScalableThumbnail(DbManager db, ceScalableThumbnail task)
        {
            try
            {
                ScalableThumbnailAccessor sta = ScalableThumbnailAccessor.CreateInstance<ScalableThumbnailAccessor>(db);
                if (sta.IsThumbnailExist(task.OrginalFileName, task.Width, task.Height))
                    return;

                ImageCodecInfo encoder;
                string ext = Path.GetExtension(task.OrginalFileName).ToLowerInvariant();
                switch (ext)
                {
                    case ".jpg":
                    case ".jpeg":
                        encoder = GetEncoder(ImageFormat.Jpeg);
                        break;

                    case ".png":
                        encoder = GetEncoder(ImageFormat.Png);
                        break;

                    case ".gif":
                        encoder = GetEncoder(ImageFormat.Gif);
                        break;

                    default:
                        throw new Exception(string.Format("Unrecognized Filename [{0}]", task.OrginalFileName));
                }

                byte[] buffer = FTP.DownloadFile(task.FilePath);
                if (buffer == null)
                    throw new Exception(string.Format("Failed to download FTP file [{0}].", task.FilePath));
                using (MemoryStream ms = new MemoryStream(buffer))
                using (MemoryStream dest = new MemoryStream())
                using (Bitmap bitmap = new Bitmap(ms))
                using (Bitmap canvas = new Bitmap(task.Width, task.Height))
                using (Graphics g = Graphics.FromImage(canvas))
                {
                    g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                    g.DrawImage(bitmap, new Rectangle(0, 0, task.Width, task.Height));

                    EncoderParameters eps = new EncoderParameters(1);
                    EncoderParameter ep = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, 95L);
                    eps.Param[0] = ep;
                    canvas.Save(dest, encoder, eps);
                    buffer = dest.ToArray();
                }

                long domainID = task.DomainID.HasValue ? task.DomainID.Value : Constant.SystemDomainID;

                using (MD5 md5 = MD5.Create())
                {
                    byte[] bytes = md5.ComputeHash(buffer);
                    string hashCode = BitConverter.ToString(bytes).Replace("-", "");
                    string filePath = string.Format("/_casino/{0}/{1}{2}"
                        , hashCode[0]
                        , hashCode
                        , ext
                        );
                    FTP.UploadFile(domainID, filePath, buffer);
                    task.FilePath = filePath;
                }

                SqlQuery<ceScalableThumbnail> query = new SqlQuery<ceScalableThumbnail>(db);
                query.Insert(task);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }
    }
}
