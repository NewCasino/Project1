<%@ Page Language="C#" MasterPageFile="~/Views/System/TopBar.master" Inherits="CM.Web.ViewPageEx<dynamic>"%>
<%@ Import Namespace="BLToolkit.Data" %>
<%@ Import Namespace="BLToolkit.DataAccess" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script type="text/C#" runat="server">
private List<SelectListItem> GetOperatorList()
{
    List<SelectListItem> list = SiteManager.GetSites()
        .Where( s => !s.DisplayName.StartsWith("[", StringComparison.InvariantCultureIgnoreCase) )
        .Select(s => new SelectListItem() { Text = s.DisplayName, Value = s.DistinctName })
        .OrderBy(s => s.Text)
        .ToList();

    list.Insert(0, new SelectListItem() { Selected = true, Text = "< All Operators >", Value = string.Empty });
    return list;
}

private string GetDefaultDate()
{
    return string.Format("{0:D4}-{1:D2}-{2:D2}"
        , DateTime.UtcNow.Year
        , DateTime.UtcNow.Month
        , DateTime.UtcNow.Day
        );
}

private List<string> GetServers()
{
    using (DbManager db = new DbManager("Log"))
    {
        LogAccessor ls = LogAccessor.CreateInstance<LogAccessor>(db);
        return ls.GetServers();
    }    
}
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content("~/js/jquery/jquery.ui/redmond/jquery-ui-1.8.custom.css") %>" />
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/Monitor/Index.css") %>" />
    <script type="text/javascript" src="/js/highchart/highstock.js"></script>
    <script type="text/javascript" src="/js/highchart/themes/grid.js"></script>
    <script type="text/javascript" src="/js/jquery/jquery.maskedinput-1.3.min.js"></script>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">


<div id="monitor-form-wrapper">
<table cellpadding="15">
    <tr>
        <td>
            <%: Html.DropDownList( "operatorName", GetOperatorList(), new { @id = "ddlOperator" }) %>
        </td>
        <td>
            <strong>UTC Date</strong> : <%: Html.TextBox("date", GetDefaultDate(), new { @id = "txtSearchDate", autocomplete="off" })%>
        </td>
        <td>
            <button id="btnSubmit" type="button">Submit</button>
        </td>
        <td>
            <strong>Current UTC Time</strong> : <%= DateTime.UtcNow.ToString() %>
        </td>
    </tr>
</table>


<hr/>
<div id="overrall-chat" class="chart-wrapper" data-server=""></div>

<% 
    foreach (string server in GetServers())
    { %>

    <div id="_<%= Guid.NewGuid().ToString("N") %>" class="chart-wrapper" data-server="<%= server %>"></div>

<%  } %>

</div>

<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
    $(function () {
        if (self != top) top.location = self.location;

        $("#txtSearchDate").mask("9999-99-99");

        Highcharts.setOptions({
            global: {
                useUTC: true
            }
        });

        $('#btnSubmit').click(function (e) {
            $('div.chart-wrapper').html('<img src="/images/icon/loading.gif" />');

            $('div.chart-wrapper').each(function (i, el) {
                var fun = (function (o) {
                    return function () {
                        var json = arguments[0];
                        if (!json.success) {
                            alert(json.error);
                            return;
                        }
                        loadChart(json, o, (o.data('server') == '' ? 'Overrall' : o.data('server')));
                    };
                })($(el));

                var p = {};
                p.operatorName = $('#ddlOperator').val();
                p.server = $(el).data('server');
                p.date = $('#txtSearchDate').val();
                p.t = (new Date()).getTime();
                $(el).data('server', p.server);
                $(el).data('operatorName', p.operatorName);
                $.getJSON('/Monitor/QueryStatistics', p, fun);
            });

        }).click();




        function loadChart(json, $container, title) {

            var openWindow = function (x) {
                var url = '/LogViewer/AccessLog/?minuteStamp=' + x + '&server=' + $container.data('server') + '&op=' + $container.data('operatorName');
                window.open(url, "_blank");
            };

            // Create the chart
            new Highcharts.StockChart({
                chart: {
                    renderTo: $container.attr('id'),
                    height: $container.height(),
                    borderWidth: 0
                },

                tooltip: {
                    crosshairs: true,
                    shared: true
                },

                legend: {
                    enabled: true,
                    verticalAlign: "top",
                    align: "right",
                    floating: true
                },

                title: {
                    align: "left",
                    text: title
                },

                plotOptions: {
                    column: {
                        marker: {
                            enabled: true
                        },
                        events: {
                            click: function (evt) {
                                openWindow(evt.point.x / 1000);
                            }
                        }     
                    },
                    spline: {
                        marker: {
                            enabled: false
                        },
                        shadow: true,
                        events: {
                            click: function (evt) {
                                openWindow(evt.point.x / 1000);
                            }
                        }
                    }
                },

                rangeSelector: {
                    buttons: [{
                        count: 15,
                        type: 'minute',
                        text: '15M'
                    }, {
                        count: 30,
                        type: 'minute',
                        text: '30M'
                    }
                    , {
                        count: 60,
                        type: 'minute',
                        text: '1H'
                    }
                    , {
                        count: 120,
                        type: 'minute',
                        text: '2H'
                    }, {
                        count: 180,
                        type: 'minute',
                        text: '3H'
                    }, {
                        count: 360,
                        type: 'minute',
                        text: '6H'
                    }, {
                        count: 720,
                        type: 'minute',
                        text: '12H'
                    }, {
                        count: 1,
                        type: 'day',
                        text: '1D'
                    }],
                    inputEnabled: false,
                    selected: 1
                },


                series: [{
                    name: 'Request Number',
                    type: 'column',
                    data: json.requestNumber,
                    tooltip: {
                        valueDecimals: 0
                    },
                    color: '#92B5CA'
                }, {
                    name: 'Avg Execution Time',
                    data: json.avgExecutionSeconds,
                    type: 'spline',
                    tooltip: {
                        valueDecimals: 2,
                        valueSuffix: ' s'
                    },
                    yAxis: 1,
                    color: '#AA4643'
                }, {
                    name: '90% Avg Execution Time',
                    data: json.ninetyPercentAvgExecutionSeconds,
                    type: 'spline',
                    tooltip: {
                        valueDecimals: 2,
                        valueSuffix: ' s'
                    },
                    yAxis: 1,
                    dashStyle: 'shortdot',
                    color: '#DB843D'
                }, {
                    name: 'Standard Deviation',
                    data: json.standardDeviation,
                    type: 'spline',
                    tooltip: {
                        valueDecimals: 2
                    },
                    yAxis: 1,
                    color: '#80699B',
                    dashStyle: 'shortDash'
                }],

                xAxis: {
                    gridLineWidth: 0,
                    dateTimeLabelFormats: {
                        second: '%H:%M'
                    },
                    ordinal: false
                },
                yAxis: [{
                    min: 0,
                    gridLineWidth: 0,
                    title: {
                        text: 'Request Number'
                    }
                }, {
                    min: 0,
                    labels: {
                        formatter: function () {
                            return this.value + ' s';
                        }
                    },
                    gridLineWidth: 0,
                    title: {
                        text: 'Avg Execution Time'
                    },
                    opposite: true
                }]
            });
        }


    });
</script>
</ui:MinifiedJavascriptControl>
</asp:Content>

