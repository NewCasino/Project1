<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<script runat="server">
    protected string CheckAcceptedTerms()
    {
        string result = "";
        if (this.GetMetadata(".EnabledPopup").Equals("yes", StringComparison.InvariantCultureIgnoreCase))
        {
            if (this.GetMetadata(".EnabledMinorPopup").Equals("yes", StringComparison.InvariantCultureIgnoreCase) &&
                IsAcceptMinorUpdateTermsNotice())
            {
                result = "Minor";
            }
            if (this.GetMetadata(".EnabledMajorPopup").Equals("yes", StringComparison.InvariantCultureIgnoreCase) &&
                IsAcceptMajorUpdateTermsNotice())
            {
                result = "Major";
            }
        }
        return result;
    }
    protected bool IsAcceptMajorUpdateTermsNotice()
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(Profile.UserID);
        TimeSpan span = (TimeSpan)(DateTime.Now - user.Ins);
        return span.Days > 5 && user.IsGeneralTCAccepted && !user.IsTCAcceptRequired.HasFlag(TermsConditionsChange.UpateNoticeMajor);
    }
    protected bool IsAcceptMinorUpdateTermsNotice()
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(Profile.UserID);
        TimeSpan span = (TimeSpan)(DateTime.Now - user.Ins);
        return span.Days > 5 && user.IsGeneralTCAccepted && !user.IsTCAcceptRequired.HasFlag(TermsConditionsChange.UpateNoticeMinor);
    }
    protected string GetNewMetadataPath(string path, string status)
    {
        return path + "_" + status;
    }

    protected bool IsAxcceptUKTerms()
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(Profile.UserID);
        return user.IsTCAcceptRequired.HasFlag(TermsConditionsChange.UKLicense);
    }
</script>
<% if (Profile.IsAuthenticated && (Profile.IpCountryID == 230 || Profile.UserCountryID == 230))
    {
        bool isDeposit = Request.Url.PathAndQuery.ToLower().IndexOf("/deposit") >= 0;
        bool isHideForUKPopUp = Settings.IsUKLicense && !IsAxcceptUKTerms();
        string status = CheckAcceptedTerms();
        if (isDeposit && isHideForUKPopUp)
        {
            status = "";
        }
        if (!string.IsNullOrEmpty(status))
        {
         %>
<%=this.GetMetadata(".CustomCSS").HtmlEncodeSpecialCharactors() %>
<div class="UKTermsConditions" id="UKTermsConditions">
    <ul class="uktc-wraper">
        <li class="uktc-item termsconditions">
            <%= Html.InformationMessage(this.GetMetadata(GetNewMetadataPath(".Html", status)).HtmlEncodeSpecialCharactors(), true) %>
        </li>
        <%
            if (status == "Major")
            {

             %>
        <li class="uktc-item cbx-axccept">
            <input id="uk-cbx-axcceptUK" type="checkbox" value="1" />&nbsp;&nbsp;<%=this.GetMetadata(GetNewMetadataPath(".CheckBox_Label", status)).HtmlEncodeSpecialCharactors() %>
        </li>
        <%} %>
        <li class="btns-wraper">
            <%=Html.Button(this.GetMetadata(status != "Major" ? ".BTN_Label" :".BTN_Submit_Label").HtmlEncodeSpecialCharactors(), new { @id = "btn-UKTermsConditions" }) %>
        </li>
    </ul>
</div>
<script type="text/javascript">
    var bd = top.document.body;
    $("#UKTermsConditions").appendTo("body");
    $(".UKTermsConditionsMask").show(); 
    $("#btn-UKTermsConditions").click(function () {
        <%if (status == "Major")
    {%>
            if ($("#uk-cbx-axcceptUK:checked").length === 0) {
                alert("<%=this.GetMetadata(".InformMsg").SafeJavascriptStringEncode() %>");
                return;
            }
        <%}%>
            var tempTermsId = "<%=status%>" == "Major" ? 8 : "<%=status%>" == "Minor" ? 16 : 0;
            $.post("/Deposit/AcceptTerms", { termsId: tempTermsId }, function (data) {
                if (data.Success) {
                    $("#UKTermsConditions").hide();
                    $(".UKTermsConditionsMask").hide();
                    $("#UKTermsConditions .closeIcon").trigger("click");
                }
                else {
                    alert(data.msg);
                }
            });
        });
        $("#UKTermsConditions .closeIcon").click(function () {
            $("#UKTermsConditions").hide();
            $(".UKTermsConditionsMask").hide();
        });
</script>
<% 
        }
    }
%>