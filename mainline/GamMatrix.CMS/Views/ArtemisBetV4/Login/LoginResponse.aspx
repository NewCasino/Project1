<%@ Page Language="C#" Inherits="CM.Web.ViewPageEx<dynamic>" %>
<%@ Import Namespace="CM.State" %>
<script type="text/C#" runat="server">
    private CustomProfile.LoginResult? LoginResult 
    {
        get
        {
            if (this.ViewData["LoginResult"] == null)
                return null;
            return (CustomProfile.LoginResult)this.ViewData["LoginResult"]; 
        } 
    }
    private string Error_NoMatch { 
        get {
            return Metadata.Get("/Metadata/ServerResponse.Login_NoMatch");
        } 
    }
    private string Error { get { return this.ViewData["Error"] as string; } }

    private bool Success { get { return (bool)this.ViewData["Success"]; } }

    private string SecondFactorAuthQrCodeUrl { get { return this.ViewData["SecondFactorAuthQrCodeUrl"] as string; } }

    private string SecondFactorAuthSetupCode { get { return this.ViewData["SecondFactorAuthSetupCode"] as string; } }

    private string PhoneNumber 
    { 
        get 
        { 
            if (this.ViewData["PhoneNumber"] != null) 
                return this.ViewData["PhoneNumber"] as string; 
            else return string.Empty; 
        } 
    }
</script>

<!DOCTYPE html>
<html>
<head>
<title></title>
</head>


<body class="<%= this.LoginResult.Value%>">

<%
    
    StringBuilder script = new StringBuilder();
    if (this.LoginResult != null && this.LoginResult.Value == CustomProfile.LoginResult.RequiresCaptcha)
    {
        script.AppendLine(@"parent.OnRequiresCaptcha();");  
    }
    else if (this.LoginResult != null && this.LoginResult.Value == CustomProfile.LoginResult.NoMatch_RequiresCaptcha)
    {
        script.AppendFormat(@"parent.OnRequiresCaptcha('{0}');", this.Error_NoMatch.SafeJavascriptStringEncode());
    }
    else if (this.LoginResult.Value == CustomProfile.LoginResult.RequiresSecondFactor 
        || this.LoginResult.Value == CustomProfile.LoginResult.RequiresSecondFactor_FirstTime)
    {
        // to do
        script.AppendFormat(@"secondFactorAuthSetupCode = {{'QrCodeImageUrl':'{0}', 'SetupCode':'{1}'}};", SecondFactorAuthQrCodeUrl.SafeJavascriptStringEncode(), SecondFactorAuthSetupCode.SafeJavascriptStringEncode());
        script.AppendFormat(@"parent.OnRequiresSecondFactor('{0}', secondFactorAuthSetupCode);", this.LoginResult.Value);        
    }
    else
    {
        script.Append("parent.OnLoginResponse({");

        if (this.LoginResult != null)
            script.AppendFormat(" result:'{0}',", this.LoginResult.Value.ToString().SafeJavascriptStringEncode());

        if (this.LoginResult == CustomProfile.LoginResult.Success)
            script.AppendFormat("displayName:'{0}',", Profile.DisplayName.SafeJavascriptStringEncode());

        if (!string.IsNullOrEmpty(PhoneNumber))
        {
            script.AppendFormat("phoneNumber:'{0}',", this.PhoneNumber.ToString().ToLowerInvariant());
        }

        script.AppendFormat("success:{0},", this.Success.ToString().ToLowerInvariant());
        script.AppendFormat("error:'{0}'", this.Error.SafeJavascriptStringEncode().Replace("\r\n", " ").Replace("\n", " "));
        script.Append("});");
    }
%>

<script type="text/javascript">
var success = false;
try
{
<%= script.ToString() %> ;
success = true;
}
catch(e)
{
}

if (window.location.toString().indexOf('.gammatrix-dev.net') > 0)
    document.domain = document.domain;
else
    document.domain = '<%= SiteManager.Current.SessionCookieDomain.SafeJavascriptStringEncode() %>';

if( !success )
{
    try
    {
    <%= script.ToString() %> 
    }
    catch(e)
    {console.log('error:'+e.message);
    }
}

</script>



</body>

</html> 