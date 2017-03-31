<%@ Page Language="C#" MasterPageFile="~/Views/System/TopBar.master" Inherits="CM.Web.ViewPageEx<dynamic>" %>

<asp:Content ContentPlaceHolderID="cphHead" runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/Dashboard/Index.css") %>" />
    <link rel="stylesheet" type="text/css" href="<%= Url.Content("~/js/jquery/jquery.ui/redmond/jquery-ui-1.8.custom.css") %>" />
</asp:Content>
<asp:Content ContentPlaceHolderID="cphMain" runat="Server">
    <div id="accordion-wrap" class="ui-widget-content">
        <div align="right">
            <button type="button" id="btnClearDomainCache">
                Reload domain configration</button>
            <button type="button" id="btnRefresh">
                Refresh</button>
            <input type="checkbox" id="btnAutoRefresh" checked="checked" />
            <label for="btnAutoRefresh">Auto Refresh?</label>
            
            
        </div>
        <% NameValueCollection servers = this.ViewData["servers"] as NameValueCollection;
           if (servers != null)
           {
               foreach (var item in servers)
               { 
        %>
        <div class="accordion ui-accordion ui-widget ui-helper-reset ui-accordion-icons">
            <h3 class="ui-accordion-header ui-helper-reset ui-state-default  ui-corner-top">
                <span class="ui-icon ui-icon-triangle-1-s"></span><a href="#">
                    <%= (item as string).SafeHtmlEncode() %>:
                    <%= (servers.Get(item as string) as string).SafeHtmlEncode() %><img src="/images/icon/loading.gif"
                        class="loading" style="float: right" /></a></h3>
            <div class="ui-accordion-content ui-helper-reset ui-widget-content ui-corner-bottom ui-accordion-content-active"
                server="<%= HttpUtility.UrlEncode(item as string).SafeHtmlEncode() %>">
                <ul>
                    <li><strong>System</strong>
                        <ul class="osInfo">
                        </ul>
                    </li>
                    <li><strong>CPU</strong>
                        <ul class="cpuLoad">
                        </ul>
                    </li>
                    <li><strong>Memory</strong>
                        <ul class="memoryUsage">
                        </ul>
                    </li>
                    <li><strong>Network</strong>
                        <ul class="networkStatus">
                        </ul>
                    </li>
                    <li><strong>Cache</strong>
                        <ul class="cacheUsage">
                        </ul>
                    </li>
                    <li><strong>IIS</strong>
                        <ul class="iisStatus">
                        </ul>
                    </li>
                    
                </ul>
            </div>
        </div>
        <%      }
   }%>

       
    </div>


    
    <script type="text/javascript">
        var __total_request = 0;
        function GetSystemInfoHandler(div) {
            this.div = div;
            __total_request++;
            this.onResponse = function (json) {
                this.div.parent().find('img.loading').hide();
                if (!json.success) {
                    alert(json.error);
                    return;
                }
                this.div.find('ul.osInfo').html('');
                this.div.find('ul.cpuLoad').html('');
                this.div.find('ul.memoryUsage').html('');
                this.div.find('ul.cacheUsage').html('');
                this.div.find('ul.iisStatus').html('');
                this.div.find('ul.networkStatus').html('');
                if (json.osInfo != null) {
                    for (var i = 0; i < json.osInfo.length; i++) {
                        this.div.find('ul.osInfo').append('<li>' + json.osInfo[i].htmlEncode() + '</li>');
                    }
                }
                if (json.cpuLoad != null) {
                    for (var i = 0; i < json.cpuLoad.length; i++) {
                        this.div.find('ul.cpuLoad').append('<li>' + json.cpuLoad[i].htmlEncode() + '</li>');
                    }
                }
                if (json.memoryUsage != null) {
                    for (var i = 0; i < json.memoryUsage.length; i++) {
                        this.div.find('ul.memoryUsage').append('<li>' + json.memoryUsage[i].htmlEncode() + '</li>');
                    }
                }
                if (json.cacheUsage != null) {
                    for (var i = 0; i < json.cacheUsage.length; i++) {
                        this.div.find('ul.cacheUsage').append('<li>' + json.cacheUsage[i].htmlEncode() + '</li>');
                    }
                }
                if (json.iisStatus != null) {
                    for (var i = 0; i < json.iisStatus.length; i++) {
                        this.div.find('ul.iisStatus').append('<li>' + json.iisStatus[i].htmlEncode() + '</li>');
                    }
                }
                if (json.networkStatus != null) {
                    for (var i = 0; i < json.networkStatus.length; i++) {
                        this.div.find('ul.networkStatus').append('<li>' + json.networkStatus[i].htmlEncode() + '</li>');
                    }
                }

                if (--__total_request <= 0 && $('#btnAutoRefresh').is(':checked')) {
                    self.Dashboard.refresh();
                }
            };
        };

        function Dashboard() {
            self.Dashboard = this;

            this.refresh = function () {
                jQuery.each($('div.accordion > div.ui-accordion-content'),
                function (indexInArray, valueOfElement) {
                    var el = $(valueOfElement);
                    var url = '<%= Url.RouteUrl( "Dashboard", new { @action = "GetSystemInfo" }).SafeJavascriptStringEncode() %>?serverName=' + $(el).attr('server');

                    el.parent().find('img.loading').show();

                    jQuery.getJSON(url, null, (function (d) {
                        return function () {
                            (new GetSystemInfoHandler(d)).onResponse(arguments[0]);
                        };
                    })(el));
                }
            );
            };
            this.refresh();

            this.clearCache = function (cacheType) {
                if (self.startLoad) self.startLoad();
                var url = '<%= Url.RouteUrl( "Dashboard", new { @action = "ReloadCache" }).SafeJavascriptStringEncode() %>?cache=' + cacheType;
                jQuery.getJSON(url, null, function (json) {
                    if (self.stopLoad) self.stopLoad();
                    if (json.success) {
                        alert(json.status);
                    }
                    else {
                        alert(json.error);
                    }
                    return;
                });
            };
            $('#btnRefresh').button().bind('click', this, function (e) {
                e.preventDefault();
                e.data.refresh();
            });
            $('#btnClearDomainCache').button().bind('click', this, function (e) {
                e.preventDefault();
                e.data.clearCache('DomainCache');
            });
        }
        $(document).ready(function () { new Dashboard(); });
    </script>
</asp:Content>
