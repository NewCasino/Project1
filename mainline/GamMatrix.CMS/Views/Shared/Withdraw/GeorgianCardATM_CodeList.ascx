<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<GeorgianCardATMCodeInfoRec>>" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script type="text/C#" runat="server">
    private string GetStatusText(GeorgianCardATMCodeStatus status)
    {
        return this.GetMetadata(string.Format(".Status_{0}", status));
    }

    private long PageNumber { get { return (long)this.ViewData["PageNumber"]; } }
    private long TotalPages { get { return (long)this.ViewData["TotalPages"]; } }
</script>

<table cellpadding="0" cellspacing="0" border="0" class="atm-codes-table">
    <thead>
        <tr>
            <th class="col-1"><span><%= this.GetMetadata(".ListHeader_Code").SafeHtmlEncode()%></span></th>
            <th class="col-2"><span><%= this.GetMetadata(".ListHeader_Date").SafeHtmlEncode()%></span></th>
            <th class="col-3"><span><%= this.GetMetadata(".ListHeader_Status").SafeHtmlEncode()%></span></th>
            <th class="col-4"><span><%= this.GetMetadata(".ListHeader_Details").SafeHtmlEncode()%></span></th>
        </tr>
    </thead>
    <tbody>

<% 
    bool isAlternate = true;
    List<GeorgianCardATMCodeInfoRec> list = this.Model ?? new List<GeorgianCardATMCodeInfoRec>();
    foreach (GeorgianCardATMCodeInfoRec rec in list)
    {
        isAlternate = !isAlternate;
        string cssClass = string.Format("{0} {1}"
            , rec.Status
            , isAlternate ? "odd" : ""
            );
         %>
        <tr class="<%=cssClass.SafeHtmlEncode() %>">
            <td class="col-1"><span><%= rec.Code.SafeHtmlEncode() %></span></td>
            <td class="col-2"><span><%= rec.Ins.ToString("dd/MM/yyyy HH:mm")%></span></td>
            <td class="col-3"><span><%= GetStatusText(rec.Status).SafeHtmlEncode() %></span></td>
            <td class="col-4">
            
            <% if (rec.Status == GeorgianCardATMCodeStatus.Setup)
               { %>
                <%: Html.Button(this.GetMetadata(".Button_Cancel"), new { @type = "button", @code = rec.Code })%>
            <% }
               else if (rec.Terminated.HasValue)
               { %>
                <span>
                    <%= this.GetMetadataEx(".Terminated_Time", rec.Terminated.Value.ToString("dd/MM/yyyy HH:mm")).SafeHtmlEncode() %>
                </span>
           <%  }
               else
               { %>
                <span>
                    <%= this.GetMetadataEx(".Expired_Time", rec.ExpiryDate.ToString("dd/MM/yyyy HH:mm")).SafeHtmlEncode()%>
                </span>
            <% } %>
            
            </td>
        </tr>
<%  } %>


    </tbody>
    <tfoot>
    </tfoot>
</table>


<center>
    

    <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
    <%: Html.Button(this.GetMetadata(".Button_GenerateCode"), new { @id = "btnGenerateCode" })%>    

    <% if( PageNumber > 0 )
       { %>
    <%: Html.Button(this.GetMetadata(".Button_PrevPage"), new { @id = "btnATMCodePrevPage" })%>
    <% } %>

    <% if (PageNumber < TotalPages - 1)
       { %>
    <%: Html.Button(this.GetMetadata(".Button_NextPage"), new { @id = "btnATMCodeNextPage" })%>
    <% } %>
</center>

<div id="dlg-atm-popup" style="display:none">
    
</div>

<script type="text/javascript">
//<![CDATA[
    $(function () {

        $('#btnGenerateCode').click(function (e) {
            e.preventDefault();

            $('#dlg-atm-popup').html($('#dlg-template').parseTemplate({}));

            $('#dlg-atm-popup').modalex(700, 550, true, document.body);
            $('#dlg-atm-popup').parents('div.simplemodal-container').css('border', '0px').css('background-color', 'transparent');

            var url = '<%= this.Url.RouteUrl( "Withdraw", new { @action = "GenerateGeorgianCardATMCode" }).SafeJavascriptStringEncode() %>';
            $('#dlg-atm-popup').parent().html('<img border="0" src="/images/icon/loading.gif" />').load(url);
        });


        $('table.atm-codes-table td.col-4 button').click(function (e) {
            e.preventDefault();
            if (window.confirm('<%= this.GetMetadata(".Confirm_Cancellation").SafeJavascriptStringEncode() %>') != true)
                return;
            $(this).toggleLoadingSpin(true);
            var url = '<%= this.Url.RouteUrl( "Withdraw", new { @action = "CancelGeorgianCardATMCode" }).SafeJavascriptStringEncode() %>';
            $.getJSON(url, { code: $(this).attr('code') }, function () {
                $('#btnGenerateCode').toggleLoadingSpin(false);
                loadGeorgianCardATMCodeList(0);
            });
        });

        $('#btnATMCodeNextPage').click(function (e) {
            e.preventDefault();
            $(this).toggleLoadingSpin(true);
            loadGeorgianCardATMCodeList(1, function () {
                $('#btnGenerateCode').toggleLoadingSpin(false);
            });
        });

        $('#btnATMCodePrevPage').click(function (e) {
            e.preventDefault();
            $(this).toggleLoadingSpin(true);
            loadGeorgianCardATMCodeList(-1, function () {
                $('#btnGenerateCode').toggleLoadingSpin(false);
            });
        });
    });
//]]>
</script>


