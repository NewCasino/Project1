<%@ Page Title="Manage Operator Redirection" Language="C#" MasterPageFile="~/Views/System/TopBar.master" Inherits="CM.Web.ViewPageEx<List<CM.Sites.DDOSRedirectorSetting>>"%>

<%@ Import Namespace="System.Globalization" %>
<script language="C#" runat="server" type="text/C#">

</script>

<asp:Content ID="cphHead" ContentPlaceHolderID="cphHead" Runat="Server">
<link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/DDOSRedirectionMgt/Index.css") %>" />
<link rel="stylesheet" type="text/css" href="<%= Url.Content("~/js/jquery/jquery.ui/redmond/jquery-ui-1.8.custom.css") %>" />
</asp:Content>


<asp:Content ID="cphMain" ContentPlaceHolderID="cphMain" Runat="Server">
<div class="creation-wrapper">
<div class="creation-ct">
    <h3><span>Manage Operator Redirection</span></h3>
    <button type="button" class="ui-state-default maintenanceset" id="btnSaveSetting">Save</button>
    <div id="properties-links"><a href="<%= this.Url.RouteUrl( "HistoryViewer", new {  
                        @action = "Dialog",
                        @distinctName = SiteManager.Current.DistinctName.DefaultEncrypt(),
                        @relativePath = "/.config/ddosredirectionmgt.setting".DefaultEncrypt(),
                        @searchPattner = "",
                        } ).SafeHtmlEncode()  %>" target="_blank" class="history">Change history...</a>
    </div>
    <table class="content-table" cellpadding="0" cellspacing="0">
        <tr class="tab_header">
            <th>Operators</th>
            <th colspan="2">Redirection</th>
        </tr>
        <tr class="">
            <td>All</td>
            <td>
                <input type="radio" value="0" class="flag_all_no" name="flag_all" />Disable
            </td>
            <td>
                <input type="radio" value="0" class="flag_all_yes" name="flag_all" />Enable
            </td>
        </tr>
        <%
            foreach (DDOSRedirectorSetting item in Model)
           {%>
        <tr>
            <td class="label"><%=item.DomainName %></td>
            <td class="content">
                <input type="radio" value="0" class="flag_no" name="flag_<%=item.DomainID %>"<%= item.Flag ? "" : @"checked=""checked""" %> />                
                 No
            </td>
            <td>
                <input type="radio" value="1" class="flag_yes" data-domainID="<%=item.DomainID %>" name="flag_<%=item.DomainID %>"<%= item.Flag ?  @" checked=""checked""" : "" %> />                
                 Yes
            </td>
        </tr>
        <%} %>
    </table>
</div>
</div>
<script type="text/javascript">
    $(function () {
        $(".flag_all_no").click(function (e) {
            $(".flag_no").attr("checked", "checked");
            $(".flag_yes").attr("checked", "");
        });
        $(".flag_all_yes").click(function (e) {
            $(".flag_yes").attr("checked", "checked");
            $(".flag_no").attr("checked", "");
        });
        $(".flag_no").click(function () {
            $(".flag_all_yes").attr("checked","");
        });
        $(".flag_yes").click(function () {
            $(".flag_all_no").attr("checked", "");
        });
        $("#btnSaveSetting").click(function (e) {
            e.preventDefault();
            var self = $(this);
            if (confirm("Are you sure that you want to do this")) {
                var arrChecked = [];
                self.attr("disabled", "disabled").text("Saving...");
                $("input.flag_yes:checked").each(function () {
                    var tg = $(this);
                    arrChecked.push(tg.data("domainID"));
                    $("#domainIDs").val(arrChecked.join(","));
                });
                $.post("/DDOSRedirectionMgt/SaveSetting", { domainIDs: arrChecked.join(",") }, function (d) {
                    if (d && d.success) {
                        alert("save successfully!");
                        self.removeAttr("disabled").text("Save");
                    } else {
                        alert(d.msg||"fail");
                    }
                });
            }
        });
        $('#properties-links a.history').click(function (e) {
            var wnd = window.open($(this).attr('href'), null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
            if (wnd) e.preventDefault();
        });
    })
</script>
</asp:Content>



