<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<script runat="server">
    protected string CheckAcceptedTerms() {
        string result = "";
        if (!IsAcceptUKTerms()) {
            result = "UKTerms";
        }
        //if (!IsAcceptUpdateTermsNotice()) {
        //    result = "UKLicenseUpateNotice";
        //}
        return result;
    }
    protected bool IsAcceptUKTerms()
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(Profile.UserID);
        if (user == null) return false;
        return user.IsTCAcceptRequired.HasFlag(TermsConditionsChange.UKLicense);
    }
    protected bool IsAcceptUpdateTermsNotice()
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(Profile.UserID);
        return user.IsTCAcceptRequired.HasFlag(TermsConditionsChange.UpateNoticeMajor);
    }
    protected string GetNewMetadataPath(string path,string status) {
        return status == "UKTerms" ? path : path+"_" + status;
    }

</script> 
<%  string status = CheckAcceptedTerms();
    if(Profile.IsAuthenticated && Profile.UserCountryID == 230 && !IsAcceptUKTerms()) {
    
        %>
<%=this.GetMetadata(".CustomCSS").HtmlEncodeSpecialCharactors() %>
<div class="UKTermsConditions" id="UKTermsConditions">
    <ul class="uktc-wraper">
        <li class="uktc-item termsconditions">
            <%= Html.InformationMessage( this.GetMetadata( GetNewMetadataPath (".Html",status)).HtmlEncodeSpecialCharactors(), true ) %>
        </li>
        <li class="uktc-item cbx-axccept">
            <input id="uk-cbx-axcceptUK" type="checkbox" value="1" />&nbsp;&nbsp;<%=this.GetMetadata(GetNewMetadataPath (".CheckBox_Label",status)).HtmlEncodeSpecialCharactors() %>
        </li>
        <li class="btns-wraper">
            <%=Html.Button(this.GetMetadata(".BTN_Label").HtmlEncodeSpecialCharactors(),new {@id="btn-UKTermsConditions" }) %>
        </li>
    </ul>
</div>
<script type="text/javascript">
     $(function () {
        var bd = top.document.body;
        if ($(bd).find("#UKTermsConditions").length == 0) {
            $("#UKTermsConditions").appendTo(bd);
            $("#UKTermsConditions_css").appendTo(bd);
        }
        $(bd).find("#UKTermsConditions").modalex(650, 340, true, bd);
        $(bd).find("#simplemodal-container .simplemodal-close").css("display", "block");
        $(bd).find("#btn-UKTermsConditions").click(function () {
            if ($(bd).find("#uk-cbx-axcceptUK:checked").length === 0) {
                alert("<%=this.GetMetadata(GetNewMetadataPath (".InformMsg",status)).SafeJavascriptStringEncode() %>");
                return;
            }
            if ("<%=status%>" == "UKLicenseUpateNotice" && $(bd).find("#uk-cbx-axcceptUK:checked").val() == "1") {
                $.post("/Deposit/AcceptTerms", { termsId:8 }, function (data) {
                    if (data.Success)
                        $(bd).find("#simplemodal-container .simplemodal-close").trigger("click");
                    else
                        alert(data.msg);
                });
            } 
            if ("<%=status%>" == "UKTerms" && $(bd).find("#uk-cbx-axcceptUK:checked").val() == "1") {
                $.post("/Deposit/AcceptUKTerms", { status: "1" }, function (data) {
                    if (data.Success)
                        $(bd).find("#simplemodal-container .simplemodal-close").trigger("click");
                    else
                        alert(data.msg);
                });
            }
        });
    });
</script>
<% } %>