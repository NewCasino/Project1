using System;
using System.Security.Cryptography;
using System.Text;
using CM.db;

/// <summary>
/// Summary description for PasswordHelper
/// </summary>
public static class PasswordHelper
{
    public static string CreateEncryptedPassword(PasswordEncryptionMode mode, string plainPassword)
    {
        switch (mode)
        {
            case PasswordEncryptionMode.MD5:
                return plainPassword.MD5Hash(Encoding.ASCII);

            case PasswordEncryptionMode.SHA1_IntraGame:
                return EncryptIntraGamePassword(plainPassword);
            case PasswordEncryptionMode.SHA2_512:
                return EncryptPasswordWithSHA2(plainPassword);
            default:
                throw new NotImplementedException();
        }
    }

	public static string DoubleEncryptPassword(string plainPassword)
	{
        return plainPassword.MD5Hash(Encoding.ASCII).MD5Hash();
	}

    private static string EncryptIntraGamePassword(string plainPassword)
    {
        using (SHA1CryptoServiceProvider sha1 = new SHA1CryptoServiceProvider())
        {
            string input = string.Format("oR6_<2yU.]9NmQ!o??apCv-o+gr&{0}", plainPassword);
            byte[] buffer = Encoding.ASCII.GetBytes(input);

            string hexStr = BitConverter.ToString(sha1.ComputeHash(buffer)).Replace("-", "").ToLowerInvariant();
            return hexStr;
        }
    }

    private static string EncryptPasswordWithSHA2(string plainPassword)
    {
        using (SHA512Managed alg = new SHA512Managed())
        {
            byte[] buffer = alg.ComputeHash(Encoding.UTF8.GetBytes(plainPassword));
            StringBuilder hex = new StringBuilder();
            foreach (byte b in buffer)
                hex.Append(b.ToString("X2"));
            return hex.ToString().ToLowerInvariant();

        }
    }
}
