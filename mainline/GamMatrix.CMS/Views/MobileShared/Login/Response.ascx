<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CM.State" %>

<!doctype html>
<meta charset=utf-8>

<script type="text/C#" runat="server">
	private string Callback
	{
		get
		{
			return (this.ViewData["Callback"] as string).DefaultIfNullOrEmpty("alert");
		}
	}

	private bool Status
	{
		get
		{
			return this.ViewData["Status"] as bool? ?? false;
		}
	}

	private string Message
	{
		get
		{
			
			return this.ViewData["Message"] as string ?? string.Empty;
		}
	}

    private string Result
    {
        get
        {            
            return this.ViewData["Result"]  as string ?? string.Empty;
        }
    }
    private TwoFactorAuth.SecondFactorAuthSetupCode SecondFactorAuthSetupCode
    {
        get
        {            
            return this.ViewData["SecondFactorAuthSetupCode"] as TwoFactorAuth.SecondFactorAuthSetupCode;
        }
    }
    private string PhoneNumber
    {
        get
        {
            return this.ViewData["PhoneNumber"] as string ?? string.Empty;
        }
    }
</script>

<script type="text/javascript">
    var secondFactorAuthSetupCode = null;
    <%
    StringBuilder jsonSetupCode = new StringBuilder();
    if (SecondFactorAuthSetupCode != null) {
        jsonSetupCode.AppendFormat(@"secondFactorAuthSetupCode = {{'QrCodeImageUrl':'{0}', 'SetupCode':'{1}'}};", SecondFactorAuthSetupCode.QrCodeImageUrl.SafeJavascriptStringEncode(), SecondFactorAuthSetupCode.SetupCode.SafeJavascriptStringEncode());
    }%>
    <%=jsonSetupCode.ToString()%>
    parent.<%= Callback.SafeJavascriptStringEncode()%>(<%= Status.ToString().ToLowerInvariant()%>, '<%= Message.SafeJavascriptStringEncode()%>', '<%= Result.ToString().SafeJavascriptStringEncode()%>', secondFactorAuthSetupCode, '<%=PhoneNumber%>');
</script>