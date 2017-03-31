<%@ Page Language="C#" Inherits="System.Web.Mvc.ViewPage" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title></title>
</head>
<body>
    <center>
        <h2 style="color:Red"><%= (this.GetLocalResourceObject("ErrorMessage") as string).SafeHtmlEncode() %></h2>
    </center>
</body>
</html>
