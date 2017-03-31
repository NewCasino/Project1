<%@ Page Language="C#" Inherits="System.Web.Mvc.ViewPage<CE.db.ceCasinoGameBaseEx>" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title><%=Model.GameName %></title>
    <link type="text/css" href="<%= Url.Content("~/css/game_information.css") %>" rel="stylesheet" />	
</head>
<body>
    <%= ViewData["Html"] %>
    <p style="clear: both;">
        <button onclick="self.close();" style="float: right;">Close</button>
    </p>
</body>
</html>
