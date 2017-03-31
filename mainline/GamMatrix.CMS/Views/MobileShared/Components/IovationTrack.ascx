<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<script runat="server">
    private string ID { get; set; }
    protected override void OnPreRender(EventArgs e)
    {
        this.ID = string.Format(System.Globalization.CultureInfo.InvariantCulture, "_{0}", Guid.NewGuid().ToString("N").Truncate(6));
        base.OnPreRender(e);

    }
</script>
<!-- one page only need call this onece -->
<%if (Settings.IovationDeviceTrack_Enabled)
    { %>
<input type="hidden" name="iovationBlackBox" id="<%=this.ID %>" />
<input type="hidden" name="iovationBlackBox_info" id="<%=this.ID %>_info"/>
    <script type="text/javascript">
        var io_install_flash = false;   // do not install Flash
        var io_install_stm = false;     // do not install Active X
        var io_exclude_stm = 12;        // do not run Active X
        var io_enable_rip = true;       // collect Real IP information
        var io_blackbox, io_blackbox_value;
        var io_blackboxInfoFun;
        (function () {
            function log(m) {
                if (console && console.log) {
                    console.log(m);
                }
            }
            io_blackboxInfoFun = function () {
                return infoEle.val();
            }
            function addInfo(infor) {
                infoEle.val(infoEle.val() + "\r\n" + infor);
            }
            function addException(ex) {
                addInfo("name:" + ex.name + "--- message:" + ex.message);
            }
            var eleId = "<%=this.ID %>";
        var infoEle = $("#<%=this.ID %>_info");
        if (typeof ioGetBlackbox == "undefined") {
            var error = "iocation track script required!";
            addInfo(error);
            log(error);
            return;
        }
        var getCount = 0;
        try {

            var getInterval = setInterval(function () {
                io_blackbox = ioGetBlackbox();
                getCount++;
                io_blackbox_value = io_blackbox.blackbox;
                $("#" + eleId).val(io_blackbox_value);
                if (io_blackbox.finished) {
                    clearInterval(getInterval);
                    addInfo("finished get,try count:" + getCount);
                }
            }, 500);
        }
        catch (ex) {
            addInfo("try " + getCount + "times, but failed, the last value is:" + $("#" + eleId).val());
            addException(ex);
        }
    })();
    </script>

<%} %>

