<%@ Page Language="C#" Inherits="System.Web.Mvc.ViewPage" UICulture="auto" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script language="C#" type="text/C#" runat="server">

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        string lang = ViewData["ErrorLanguage"] as string;
        if (!string.IsNullOrEmpty(lang))
        {
            UICulture = lang;
        }

        string code = ViewData["ErrorCode"] as string;
        if (string.IsNullOrEmpty(code))
        {
            code = "101";
        }

        string translatedString = GetLocalResourceObject(code) as string;

        if (string.IsNullOrEmpty(translatedString))
        {
            translatedString = GetLocalResourceObject("101") as string; // default error code
        }

        string data = ViewData["ErrorMessage"] as string;
        if (!string.IsNullOrEmpty(data))
        {
            translatedString = string.Format("{0}: {1}", translatedString, data);
        }

        ViewData["ErrorMessage"] = translatedString;

    }

</script>
<html xmlns="http://www.w3.org/1999/xhtml">
    <head runat="server">
        <title>Error</title>
        <link type="text/css" href="<%= Url.Content("~/css/game_information.css") %>" rel="stylesheet"/>
    </head>
    <body>
        <div>
            <h2 style="color: red">
                <%= (ViewData["ErrorMessage"] as string).SafeHtmlEncode() %>
            </h2>
        </div>
    </body>
</html>