using System.Web.Profile;

/// <summary>
/// Profile Extension, add extension methods to profile
/// </summary>
public static class ProfileExtension
{
    /// <summary>
    /// Convert profile to CustomProfile
    /// </summary>
    /// <param name="profile"></param>
    /// <returns></returns>
    public static CM.State.CustomProfile AsCustomProfile(this ProfileBase profile)
    {
        return profile as CM.State.CustomProfile;
    }
}

