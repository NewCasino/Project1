using System;
using System.IO;
using System.Security.Cryptography;
using System.Web;

namespace CE.Utils
{
    public static class ImageAsset
    {
        public static string GetImageFtpFilePath(string filename)
        {
            if (string.IsNullOrWhiteSpace(filename))
                throw new Exception("Incorrect filename!");

            return string.Format("/_casino/{0}/{1}", filename[0], filename);
        }

        public static bool ParseImage(HttpPostedFileBase uploadedImage, out string filename, out byte[] buffer)
        {
            filename = null;
            buffer = null;

            if (uploadedImage != null && uploadedImage.InputStream.Length > 0)
            {
                string extFileName = Path.GetExtension(uploadedImage.FileName).ToLowerInvariant();
                switch (extFileName)
                {
                    case ".png":
                    case ".jpg":
                    case ".gif":
                    case ".jpeg":
                        break;

                    default:
                        throw new Exception(string.Format("[{0}] is not a valid image file!", filename));
                }
                buffer = new byte[uploadedImage.InputStream.Length];
                uploadedImage.InputStream.Position = 0;
                using (BinaryReader br = new BinaryReader(uploadedImage.InputStream))
                {
                    br.Read(buffer, 0, buffer.Length);
                }

                using (MD5 md5 = MD5.Create())
                {
                    byte[] bytes = md5.ComputeHash(buffer);
                    string hashCode = BitConverter.ToString(bytes).Replace("-", "");
                    filename = string.Format("{0}{1}"
                        , hashCode
                        , extFileName
                        );
                }
                return true;
            }

            return false;
        }
    }
}
