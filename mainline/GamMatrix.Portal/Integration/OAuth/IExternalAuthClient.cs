using System.Collections.Generic;

namespace OAuth
{
    public interface IExternalAuthClient
    {
        string GetExternalLoginUrl(ReferrerData referrer);

        ReferrerData CheckReturn(Dictionary<string, string> fields);
    }
}
