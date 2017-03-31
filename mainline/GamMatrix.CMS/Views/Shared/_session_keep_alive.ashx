<%@ WebHandler Language="C#" Class="_session_keep_alive" %>

using System;
using System.Web;

public class _session_keep_alive : IHttpHandler {
    
    public void ProcessRequest (HttpContext context) {

        int duration = 180;
        if (!int.TryParse(context.Request.QueryString["duration"], out duration))
            duration = 180;
            

        ProfileCommon.Current.Init(context);

        context.Response.ContentType = "text/html";
        context.Response.Write( string.Format( @"<!DOCTYPE html PUBLIC ""-//W3C//DTD XHTML 1.0 Transitional//EN"" ""http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"">
<html xmlns=""http://www.w3.org/1999/xhtml"">
<head>
<meta http-equiv=""Content-Type"" content=""text/html; charset=utf-8"" />
<title></title>
<meta http-equiv=""refresh"" content=""{0}"" />
<meta http-equiv=""Pragma"" content=""no-cache"" />
<meta http-equiv=""Cache-Control"" content=""no-cache"" />
<meta http-equiv=""expires"" content=""Wed, 26 Feb 1997 08:21:57 GMT"" />
<meta http-equiv=""expires"" content=""0"" />
</head>
<body>
<script type=""text/javascript"">
setTimeout( function() {{ self.location = self.location; }}, {0}000);
</script>
</body>
</html>
", duration.ToString(System.Globalization.CultureInfo.InvariantCulture) )
 );
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

}