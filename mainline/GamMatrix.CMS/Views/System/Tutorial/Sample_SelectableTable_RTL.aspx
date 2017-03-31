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
        #wrapper { width:95%; margin: 0 auto; clear:both; border:dotted 1px #000000; padding:10px; background-color:#D3D3D3; }
    </style>

    <style type="text/css" id="style">
    .selectableTable 
    {
        border-collapse:collapse; border:solid 1px #828282; background-color:#FFFFFF; font-family:"Segoe UI", Arial, "Sans-Serif";
        font-size:12px; font-weight:400; font-style:normal; user-select: none; -moz-user-select: none; -khtml-user-select: none;
    }
    .selectableTable tr { height:24px; overflow:hidden; cursor:default; }
    .selectableTable td { padding:0px 10px 0px 10px; }
    .selectableTable .alternate_Row { background-color:#F2F2F2; }
    .selectableTable .col-1 { padding-right:30px !important; text-align:right; }
    .selectableTable .col-3 { text-align:right; }
    .selectableTable .selected td { background-image:url("<%= this.ViewData["__client_base_path"] %>img/listbox_selected_row.png"); 
                                     background-repeat:no-repeat; background-position:left -24px; }
    .selectableTable .selected .col-1 { background-image:url("<%= this.ViewData["__client_base_path"] %>img/listbox_selected_row.png");
                                        background-repeat:no-repeat; background-position:right -48px !important; }
    .selectableTable .selected td { color:#FFFFFF !important; } 
    </style>
</head>


<body dir="rtl">

<div id="wrapper">
<% using( var table = Html.BeginSelectableTable( "gammingAccount", "2", "ID", new { @id="table_gamming_account" }) )
   {
       table.DefineColumns(
           new SelectableTableColumn()
           {
               DateFieldName = "DisplayName"
           },
           new SelectableTableColumn()
           {
               DateFieldName = "Currency"
           },
           new SelectableTableColumn()
           {
               DateFieldName = "Amount"
           }
       );

       table.RenderRow(new { @DisplayName = "ספורט", @Currency = "EUR", @Amount = "0.00", @ID = 1 });

       table.RenderRows( new object[] 
        {
            new { @DisplayName = "קזינו", @Currency = "EUR", @Amount = "12.55", @ID = 2 },
            new { @DisplayName = "משחקי קלפים", @Currency = "USD", @Amount = "0.00", @ID = 3 },
            new { @DisplayName = "פוקר", @Currency = "GBP", @Amount = "221.00", @ID = 4 },
            new { @DisplayName = "שותפים", @Currency = "EUR", @Amount = "10000.00", @ID = 5 },
        });
   }
 %>

</div>
<br />
<hr />

<table class="table-info" cellpadding="0" cellspacing="0" border="1" rules="all">
    <tr class="alternate-row">
        <td class="col-1">Server tag sample</td>
        <td class="col-2"><pre>
</pre></td>
    </tr>
    <tr>
        <td class="col-1">Server script sample</td>
        <td class="col-2"><pre>using( var table = Html.BeginSelectableTable( "gammingAccount", "2", "ID", new { @id="table_gamming_account" }) )
{
    table.OnClientSelectionChanged = "onGammingAccountChanged";
    table.DefineColumns(
        new SelectableTableColumn()
        {
            DateFieldName = "DisplayName"
        },
        new SelectableTableColumn()
        {
            DateFieldName = "Currency"
        },
        new SelectableTableColumn()
        {
            DateFieldName = "Amount"
        }
    );

    table.RenderRow(new { @DisplayName = "Sports", @Currency = "EUR", @Amount = "0.00", @ID = 1 });

    table.RenderRows( new object[] 
     {
         new { @DisplayName = "Casino", @Currency = "EUR", @Amount = "12.55", @ID = 2 },
         new { @DisplayName = "Card Games", @Currency = "USD", @Amount = "0.00", @ID = 3 },
         new { @DisplayName = "Poker", @Currency = "GBP", @Amount = "221.00", @ID = 4 },
         new { @DisplayName = "Affiliate", @Currency = "EUR", @Amount = "10000.00", @ID = 5 },
     });
}</pre></td>
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
function onGammingAccountChanged(key, data) {
    alert( 'You have selected the [' + data.DisplayName + '] account');
}
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



