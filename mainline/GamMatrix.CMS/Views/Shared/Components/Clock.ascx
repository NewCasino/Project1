<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<script runat="server">
    private string ID { get; set; }
    protected override void OnInit(EventArgs e)
    {
        this.ID = "_" + Guid.NewGuid().ToString("N").Truncate(5);

        base.OnInit(e);
    }

</script>
<script type="text/C#" runat="server">
    private bool SampleDisplay
    {
        get
        {
            if (this.ViewData["SampleDisplay"] == null)
            {
                return this.GetMetadata(".SampleDisplay").ParseToBool(false);
            }
            else if (string.IsNullOrWhiteSpace(this.ViewData["SampleDisplay"].ToString()))
            {
                return this.GetMetadata(".SampleDisplay").ParseToBool(false);
            }
            else
                return this.ViewData["SampleDisplay"].ToString().ParseToBool(false);
        }
    }
</script>
<%= this.GetMetadata(".CSS") %>
<div id="current_time">
</div>
<script type="text/javascript">
    (function () {
        var id = "current_time";
        var additionalWords = '<%= this.GetMetadata(".Additional_words") %>';
        var day = 0;
        var newDay = 1;
        var dayStr = "";
        var useSampleClock = false;
        var SundayStr = '<%= this.GetMetadata("/Metadata/Date/Day/Sunday.ShortName").SafeHtmlEncode()  %>';
        var MondayStr = '<%= this.GetMetadata("/Metadata/Date/Day/Monday.ShortName").SafeHtmlEncode()  %>';
        var TuesdayStr = '<%= this.GetMetadata("/Metadata/Date/Day/Tuesday.ShortName").SafeHtmlEncode()  %>';
        var WednesdayStr = '<%= this.GetMetadata("/Metadata/Date/Day/Wednesday.ShortName").SafeHtmlEncode()  %>';
        var ThursdayStr = '<%= this.GetMetadata("/Metadata/Date/Day/Thursday.ShortName").SafeHtmlEncode()  %>';
        var FridayStr = '<%= this.GetMetadata("/Metadata/Date/Day/Friday.ShortName").SafeHtmlEncode()  %>';
        var SaturdayStr = '<%= this.GetMetadata("/Metadata/Date/Day/Saturday.ShortName").SafeHtmlEncode()  %>';
    <% if (SampleDisplay == true)
    { %>
        useSampleClock = true;
    <% } %>
        var timer;
        function getCurrentTime() {
            if ($("#" + id).length == 0) {
                if (!!timer) {
                    clearInterval(timer);
                }
                return;
            }
            var t = new Date();
            var h = t.getHours();
            var m = t.getMinutes();
            if (h < 10) h = "0" + h;
            if (m < 10) m = "0" + m;
            if (useSampleClock == true) {
                document.getElementById(id).innerHTML = h + ":" + m;
            }
            else {
                var s = t.getSeconds();
                newDay = t.getDay();
                if (newDay != day) {
                    day = newDay;
                    getDay();
                }
                if (s < 10) s = "0" + s;
                document.getElementById(id).innerHTML = h + ":" + m + ":" + s + dayStr + additionalWords;
            }
        }
        function getDay() {
            switch (day) {
                case 0:
                    dayStr = SundayStr;
                    break;
                case 1:
                    dayStr = MondayStr;
                    break;
                case 2:
                    dayStr = TuesdayStr;
                    break;
                case 3:
                    dayStr = WednesdayStr;
                    break;
                case 4:
                    dayStr = ThursdayStr;
                    break;
                case 5:
                    dayStr = FridayStr;
                    break;
                case 6:
                    dayStr = SaturdayStr;
                    break;
            }
        }
        timer = setInterval(getCurrentTime, 1000);
    })();
</script>
