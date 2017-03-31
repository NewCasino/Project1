<%@ Page Language="C#" AutoEventWireup="true"  %>

<%@ Import Namespace="CM.db" %>
<script language="C#" type="text/C#" runat="server">
    private string GetPostUrl()
    {
        string uid = Request["uid"];
        string action = Request["action"];
        if (string.IsNullOrEmpty(uid) || string.IsNullOrEmpty(action))
            throw new Exception("Incorrect query parameters.");

        switch (action.ToLowerInvariant())
        {
            case "ok":
                return cmTransParameter.ReadObject<string>(uid, "SuccessUrl");

            case "cancel":
                return cmTransParameter.ReadObject<string>(uid, "CancelUrl");

            case "error":
                return cmTransParameter.ReadObject<string>(uid, "ErrorUrl");
                
            default:
                return string.Empty;
        }        
    }
</script>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>

<form>
    <% foreach (string name in Request.QueryString)
        { %>
        <input type="hidden" name="<%= name.SafeHtmlEncode() %>" value="<%= Request.QueryString[name].SafeHtmlEncode() %>" />           
    <% } %>
</form>

<script language="javascript" type="text/javascript">
    window.onload = function () {
        var form = document.getElementsByTagName('form')[0];
        form.setAttribute('action', '<%= GetPostUrl().SafeJavascriptStringEncode() %>');
        form.setAttribute('method', 'post');
        form.setAttribute('target', '_self');
        form.setAttribute('enctype', 'application/x-www-form-urlencoded');
        form.submit();
    };
</script>

</body>
</html>
