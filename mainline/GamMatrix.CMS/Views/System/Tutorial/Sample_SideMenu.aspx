<%@ Page Title="<%$ Metadata:value(.Title) %>" Language="C#" Inherits="CM.Web.ViewPageEx<dynamic>"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/combined.js") %>"></script>
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/inputfield.js") %>"></script>
    <style type="text/css">
        html, body { background-color:White; font-family:Consolas; font-size:12px; color:Black; font-style:normal; }
        .table-info { width:100%; border: solid 1px #B3CC82; }
        .table-info td { padding:5px; background-color:#E6EED5; }
        .table-info .alternate-row td { background-color:#CDDDAC !important; }
        .table-info .col-1 { font-weight:600; }
        #wrapper { width:200px; margin-left: 10px; clear:both; border:dotted 1px #000000; padding:10px; background-color:Black;  }
    </style>

    <style type="text/css" id="style">
    .sidemenu { display:block; }
    .sidemenu ul { margin:0px; padding:0px; list-style-type:none; }
    .sidemenu li { margin:0px; padding:0px; }
    .sidemenu .children { margin-left:20px; }
    .sidemenu .collapsed { display:none; }
    .sidemenu li span { display:block; border-bottom:solid 1px #454545; height:19px; line-height:19px; vertical-align:middle; background:url("<%= this.ViewData["__client_base_path"] %>img/sidemenu.png") left top no-repeat; }
    .sidemenu li span a { text-decoration:none; margin-left:20px; color:white; text-transform:uppercase; }
    .sidemenu .selected span { background-color:#136484 !important; }
    
    .sidemenu a:hover { color:#CCCCCC !important; }
    </style>
</head>


<body>

<div id="wrapper">

<% using( NavigationMenu menu = this.Html.BeginNavigationMenu( MenuType.SideMenu ) )
   {
       menu.Items.Add( new NavigationMenuItem() { NagivationUrl = "#", Text = "Deposit" } );
       menu.Items.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Withdraw" });
       menu.Items.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Transfer" });
       menu.Items.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Buddy Transfer" });
       menu.Items.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Account Statement" });

       NavigationMenuItem item = new NavigationMenuItem() { NagivationUrl = "#", Text = "Responsible Gaming" };
       item.Children.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Deposit Limit" });
       item.Children.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Self Exclusion", IsSelected = true });
       menu.Items.Add(item);

       item = new NavigationMenuItem() { Text = "Available bonus" };
       item.Children.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Sports Bonus" });
       item.Children.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Poker Bonus" });
       item.Children.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Casino Bonus" });
       menu.Items.Add(item);
   } %>


</div>
<br />
<hr />

<table class="table-info" cellpadding="0" cellspacing="0" border="1" rules="all">
    <tr class="alternate-row">
        <td class="col-1">Server tag sample</td>
        <td class="col-2"><pre> </pre></td>
    </tr>
    <tr>
        <td class="col-1">Server script sample</td>
        <td class="col-2"><pre>&lt;% using( NavigationMenu menu = this.Html.BeginNavigationMenu( MenuType.SideMenu ) )
   {
       menu.Items.Add( new NavigationMenuItem() { NagivationUrl = "#", Text = "Deposit" } );
       menu.Items.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Withdraw" });
       menu.Items.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Transfer" });
       menu.Items.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Buddy Transfer" });
       menu.Items.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Account Statement" });

       NavigationMenuItem item = new NavigationMenuItem() { NagivationUrl = "#", Text = "Responsible Gaming" };
       item.Children.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Deposit Limit" });
       item.Children.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Self Exclusion", IsSelected = true });
       menu.Items.Add(item);

       item = new NavigationMenuItem() { NagivationUrl = "#", Text = "Available bonus" };
       item.Children.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Sports Bonus" });
       item.Children.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Poker Bonus" });
       item.Children.Add(new NavigationMenuItem() { NagivationUrl = "#", Text = "Casino Bonus" });
       menu.Items.Add(item);
   } %&gt;
</pre></td>
    </tr>
    <tr class="alternate-row">
        <td class="col-1">Client HTML sample</td>
        <td class="col-2"><pre id="client-html"></pre></td>
    </tr>
    <tr>
        <td class="col-1">Client CSS sample</td>
        <td class="col-2"><pre id="client-css"></pre></td>
    </tr>
   
</table>

    

<ui:ExternalJavascriptControl runat="server">
<script language="javascript" type="text/javascript">
    $(document).ready(
    function () {
        $('#client-html').text($('#wrapper').html());
        $('#client-css').text($('#style').html());
    }
);
</script>
</ui:ExternalJavascriptControl>

</body>
</html>



