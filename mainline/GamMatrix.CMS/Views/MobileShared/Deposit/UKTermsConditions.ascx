<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<script runat="server">
    protected bool IsAxcceptUKTerms()
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(Profile.UserID);
        if (user == null) return false;
        return user.IsTCAcceptRequired.HasFlag(TermsConditionsChange.UKLicense);
    }
</script>
<% if (((Profile.IsAuthenticated && Profile.UserCountryID == 230) || (!Profile.IsAuthenticated && Settings.IsUKLicense)) && !IsAxcceptUKTerms())
   { %>
<%=this.GetMetadata(".CustomCSS").HtmlEncodeSpecialCharactors() %>
<div class="UKTermsConditionsMask"></div>
<div class="UKTermsConditions" id="UKTermsConditions">
    <ul class="uktc-wraper">
        <li class="uktc-item close">
            <a href="javascript:void();" class="closeIcon Button" title="<%=this.GetMetadata(".Close").HtmlEncodeSpecialCharactors() %>"><%=this.GetMetadata(".Close").HtmlEncodeSpecialCharactors() %></a>
        </li>
        <li class="uktc-item termsconditions">
            <%= Html.InformationMessage( this.GetMetadata(".Html").HtmlEncodeSpecialCharactors(), true ) %>
        </li>
        <li class="uktc-item cbx-axccept">
            <input id="uk-cbx-axcceptUK" type="checkbox" value="1" />&nbsp;&nbsp;<%=this.GetMetadata(".CheckBox_Label").HtmlEncodeSpecialCharactors() %>
        </li>
        <li class="btns-wraper">
            <%=Html.Button(this.GetMetadata(".BTN_Label").HtmlEncodeSpecialCharactors(),new {@id="btn-UKTermsConditions",@class="Button"}) %>
        </li>
    </ul>
</div>
<script type="text/javascript">
    $(window).load(function() {
        hidelimitpopup();
    });
    function hidelimitpopup(){
        $('.limit-wrap', $('body',document)).hide();
    }
    $("#UKTermsConditions").appendTo("body");
    $(".UKTermsConditionsMask").show();
    $(function () {
        $("#btn-UKTermsConditions").click(function () {
            if ($("#uk-cbx-axcceptUK:checked").length === 0) {
                alert("<%=this.GetMetadata(".InformMsg").SafeJavascriptStringEncode() %>");
                return;
            }
            $.post("/Deposit/AcceptUKTerms", { status: $("#uk-cbx-axcceptUK:checked").val() }, function (data) {
                if (data.Success){
                    $("#UKTermsConditions .closeIcon").trigger("click");
                    $('.limit-wrap', $('body',document)).show();
                    $('.limit-overlay', $('body',document)).css("height","100%");
                }
                else
                    alert(data.msg);
            })
        });
        $("#UKTermsConditions .closeIcon").click(function () {
            $("#UKTermsConditions").hide();
            $(".UKTermsConditionsMask").hide();
            $('.limit-wrap', $('body',document)).show();
            $('.limit-overlay', $('body',document)).css("height","100%");
        });
    });
</script>
<% } %>