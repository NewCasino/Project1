<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="affiliate">
    <form id="affiliateForm" name="affiliateForm" action="<%=this.GetMetadata("/Metadata/Affiliate.formActionPath")%>" target="_top">
        <div id="login_aff"><%=this.GetMetadata("/Metadata/Affiliate.form_HiddenValue")%>
        <ul>
            <li id="usernameTitle"><%=this.GetMetadata("/Metadata/Affiliate.form_Text_Username")%></li>
            <li id="usernameCtrl">
            <div class="TextBox">
                <div class="TextBox_Right">
                <div class="TextBox_Middle">
                    <input id="username" onFocus="this.select();" name="username" type="text">
                </div>
                </div>
            </div>
            </li>
            <li id="passwordTitle"><%=this.GetMetadata("/Metadata/Affiliate.form_Text_Password")%></li>
            <li id="passwordCtrl">
            <div class="TextBox">
                <div class="TextBox_Right">
                <div class="TextBox_Middle">
                    <input id="password" onFocus="this.select();" name="password" type="password">
                </div>
                </div>
            </div>
            </li>
            <li id="loginBtnCtrl"><a id="bLogin" class="Button " onClick="aff_loginpost();" href="javascript:void(0)">
            <div class="Button_Right">
                <div class="Button_Middle"><%=this.GetMetadata("/Metadata/Affiliate.form_Button_Sumbit_Text")%></div>
            </div>
            </a></li>
            <li id="ForgotPwdCtrl"><a id="hlForgotPassword" href="<%=this.GetMetadata("/Metadata/Affiliate.form_Link_forgotPass_Url").SafeHtmlEncode()%>"><%=this.GetMetadata("/Metadata/Affiliate.form_Link_forgotPass_Text").DefaultIfNullOrEmpty("Untitled").SafeHtmlEncode()%></a></li>
            <li id="SignupNowCtrl"><a id="hlSignupNow" href="<%=this.GetMetadata("/Metadata/Affiliate.form_Link_SignUp_Url").SafeHtmlEncode()%>"><%=this.GetMetadata("/Metadata/Affiliate.form_Link_SignUp_Text").DefaultIfNullOrEmpty("Untitled").SafeHtmlEncode()%></a></div>
        </ul>
        </div>
    </form>
</div>

<script type="text/javascript">
    function aff_loginpost() {
        var uname = $("#username").val();
        var pwd = $("#password").val();
        if (uname == "" || pwd == "") {
            alert("Your username or password do not match");
        }
        else {
            $('#txtUsername').val(uname);
            $('#txtPassword').val(pwd);
            $("#affiliateForm").submit();
        }
    }

    $(function () {
        $("#affiliateForm").bind("keypress", function (e) {
            var e = e || window.event;
            var keyCode = e.keyCode;
            if (keyCode == 13) {
                aff_loginpost();
            }
        });
    });  
</script>
</asp:Content>

